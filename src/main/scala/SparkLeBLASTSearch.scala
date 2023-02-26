/* SparkLeBLASTSearch to run parallel NCBI BLAST on distributed databases*/

import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.io.{LongWritable, Text}
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.hadoop.fs.FileSystem
import org.apache.hadoop.fs.Path
import java.net.URI
import org.apache.spark.TaskContext;
import java.io.BufferedOutputStream;
import scala.math._;
import scala.util.control._;
import org.apache.spark.rdd.RDD



object SparkLeBLASTSearch {
  val hdfsAddr = "/home/karimy";
  def main(args: Array[String]) {
  val conf2 = new SparkConf().setAppName("SparkLeBLASTSearch")
    val sc = new SparkContext(conf2)
    val conf = new Configuration

    
    /* read arguments */
    val partitionsNames = args(0)
    val queryPath = args(1)
    val dbPath = args(2)
    var script = args(3)
    val dbLength: Long = args(4).toLong
    val numSeq: Long = args(5).toLong
    val gapOpen = args(6)
    val gapExtend = args(7)
    val inputFormat = args(8).toInt
    val alignmentsPerQuery = args(9).toInt

    /* Get partitions names */
    val partitionNames = sc.newAPIHadoopFile(partitionsNames, classOf[TextInputFormat], 
                                              classOf[LongWritable], classOf[Text],conf)
    
    val partitions = partitionNames.map{ case(k,v) => v};
    
    /* Set arguments for NCBI BLAST */
    script = script + " " + queryPath + " " + dbPath + " " + dbLength.toString + " " + gapOpen +
                 " " + gapExtend + " " + inputFormat + " " + alignmentsPerQuery;

    val resultUnsorted2 = partitions.pipe(script);//.saveAsTextFile("/fastscratch/karimy/finalOutput");
   
    resultUnsorted2.saveAsTextFile("/fastscratch/karimy/finalOutput");

    if ( inputFormat == 0 ){
    
      conf.set("textinputformat.record.delimiter", "Query=")
      val resultUnsorted = sc.newAPIHadoopFile("/fastscratch/karimy/finalOutput", classOf[TextInputFormat],
                                              classOf[LongWritable], classOf[Text],conf)

    
   
      val resultByQuery = resultUnsorted.map{ case (k , v) => v.toString }
                                  .filter(segment => segment.contains("Database"))
                                  .map{ segment => (segment.split("\n")(0),"Query=" + segment) }
                                  .reduceByKey(_+"\n"+_)
                                  .repartition(resultUnsorted2.partitions.size);
      resultByQuery.saveAsTextFile("/fastscratch/karimy/finalOutputByQuery");
      val resultSplit = resultByQuery.mapValues( line => line.split("\n") );

      val resultSplit2 = resultByQuery.mapValues( line => line.split("\n>") );

      resultSplit2.mapValues(_.filter( partition => partition.contains("Score = ") ))
                .map{ case (k,v) => (k,v.mkString("\n")) };//.saveAsTextFile("finalOutoutTemp");
    
      if ( resultUnsorted.partitions.size > 1 ){
        val hsps = resultSplit.mapValues(_.filter(line => (line.contains("sp|") 
                                        || line.contains("gi|") 
                                        || line.contains("tr|")
                                        /* || line.contains("UPI")*/) 
                                        && (!line.contains(">")) && (!line.contains("Query"))
                                        && (!line.contains("No hits found"))))
                           .mapValues(_.map(line => (line,line.split(" +")(line.split(" +").length-2).toDouble.toInt)).sortBy(-_._2));
        hsps.map{ case (k,v) => (k,v.mkString("\n")) }.saveAsTextFile("/fastscratch/karimy/finalOutputFiltered");

        val hspsExpanded = resultSplit2.mapValues(_.filter( partition => partition.contains("Score = ") && 
                                              !partition.contains("Searching...") )
                                              .map( partition => (partition , partition.split("Score =\\s+")(1)
                                              .split(" ")(0).toFloat) )
                                              .sortBy(-_._2)
                                              .map{ case ( k , v ) => k })
                                              .map{ case (k,v) => (k,v.mkString("\n")) }
                                              .saveAsTextFile("/fastscratch/karimy/finalOutputExpanded");   
      } 
    }
    else if (inputFormat == 6){
        // output format 8 merging logic goes here
        conf.set("textinputformat.record.delimiter", "\n")
        val resultUnsorted = sc.newAPIHadoopFile("/fastscratch/karimy/finalOutput", classOf[TextInputFormat],
                                              classOf[LongWritable], classOf[Text],conf)
        val resultByQuery = resultUnsorted.map{ case (k , v) => v.toString }
                                  .filter(line => line.split("\t").length > 2)
				  .map{ segment => (segment.split("\t")(0),"" + segment) }
                                  .reduceByKey(_+"\n"+_)
                                  .repartition(resultUnsorted2.partitions.size);
        resultByQuery.saveAsTextFile("/fastscratch/karimy/finalOutputByQuery");
        val resultSorted = resultByQuery.mapValues( line => line.split("\n"))
                                        .mapValues(
        _.map(result => (result,result.split("\t")(result.split("\t").length - 2).toDouble)).sortBy(_._2).take(alignmentsPerQuery));
        resultSorted.map{ case (k,v) => v.mkString("\n") }.saveAsTextFile("/fastscratch/karimy/finalOutputSorted");

    }
    
    sc.stop
    }
}
