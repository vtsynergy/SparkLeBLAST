/* SparkLeBLASTSearch to run parallel NCBI BLAST on distributed databases*/

import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.io.{LongWritable, Text}
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.hadoop.fs.FileSystem
import org.apache.hadoop.fs.Path
import org.apache.hadoop.fs.FileUtil
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
    val outputFormat = args(6).toInt
    val alignmentsPerQuery = args(7).toInt
    val ncbiBlastPath = args(8)
    val slbWorkDir = args(9)
    val outputPath = args(10)

    /* Get partitions names */
    val partitionNames = sc.newAPIHadoopFile(partitionsNames, classOf[TextInputFormat], 
                                              classOf[LongWritable], classOf[Text],conf)
    
    val partitions = partitionNames.map{ case(k,v) => v};
    
    /* Set arguments for NCBI BLAST */
    script = script + " " + queryPath + " " + dbPath + " " + dbLength.toString;

    val resultUnsorted2 = partitions.pipe(script, env=Map("NCBI_BLAST_PATH" -> ncbiBlastPath , "SLB_WORKDIR" -> slbWorkDir)); //.saveAsTextFile("/fastscratch/karimy/finalOutput");

    /* Get partition size (from rdd size) */
    val rddSize = resultUnsorted2.map(_.getBytes("UTF-8").length.toLong).reduce(_+_)
    val partitionSize = rddSize / resultUnsorted2.partitions.length
    println("rddSize: " + rddSize.toString)
    println("partitionSize: " + partitionSize.toString)
    conf.set("mapreduce.input.fileinputformat.split.minsize", partitionSize.toString)

   
    resultUnsorted2.saveAsTextFile(outputPath + "/output_intermediate");

    if ( outputFormat == 0 ){
    
      conf.set("textinputformat.record.delimiter", "Query=")
      val resultUnsorted = sc.newAPIHadoopFile(outputPath + "/output_intermediate", classOf[TextInputFormat],
                                              classOf[LongWritable], classOf[Text],conf)

    
   
      val resultByQuery = resultUnsorted.map{ case (k , v) => v.toString }
                                  .filter(segment => segment.contains("Database"))
                                  .map{ segment => (segment.split("\n")(0),"Query=" + segment) }
                                  .reduceByKey(_+"\n"+_);
      resultByQuery.saveAsTextFile(outputPath + "/output_grouped_by_query");
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
        hsps.map{ case (k,v) => (k,v.mkString("\n")) }.saveAsTextFile(outputPath + "/output_filtered");

        val hspsExpanded = resultSplit2.mapValues(_.filter( partition => partition.contains("Score = ") && 
                                              !partition.contains("Searching...") )
                                              .map( partition => (partition , partition.split("Score =\\s+")(1)
                                              .split(" ")(0).toFloat) )
                                              .sortBy(-_._2)
                                              .map{ case ( k , v ) => k })
                                              .map{ case (k,v) => (k,v.mkString("\n")) }
                                              .saveAsTextFile(outputPath + "/output_expanded");   
      } 
    }
    else if (outputFormat == 6){
        // output format 8 merging logic goes here
        conf.set("textinputformat.record.delimiter", "\n")
        val resultUnsorted = sc.newAPIHadoopFile(outputPath + "/output_intermediate", classOf[TextInputFormat],
                                              classOf[LongWritable], classOf[Text],conf)
        val resultByQuery = resultUnsorted.map{ case (k , v) => v.toString }
                                  .filter(line => line.split("\t").length > 2)
				  .map{ segment => (segment.split("\t")(0),"" + segment) }
                                  .reduceByKey(_+"\n"+_);
        resultByQuery.saveAsTextFile(outputPath + "/output_grouped_by_query");
        val resultSorted = resultByQuery.mapValues( line => line.split("\n"))
                                        .mapValues(
        _.map(result => (result,result.split("\t")(result.split("\t").length - 2).toDouble)).sortBy(_._2).take(alignmentsPerQuery));

	val formattedResult = resultSorted.mapValues(_.map {
        case (result, _) =>
            val fields = result.split("\t")
            val lastField = fields.last.split(",")(0)
            (fields.init :+ lastField).mkString("\t")
    })
        // resultSorted.map{ case (k,v) => v.mkString("\n") }.saveAsTextFile(outputPath + "/output_final");
	formattedResult.map { case (k, v) => v.mkString("\n") }.saveAsTextFile(outputPath + "/output_final")

    }
    
    sc.stop
    val outputPathIntermediate = outputPath + "/output_final"
    val outputPathSingleFile = outputPath + "/final_output.txt"
    mergePartFiles(outputPathIntermediate, outputPathSingleFile)
    }

def mergePartFiles(srcPath: String, destPath: String): Unit = {
    val srcDir = new File(srcPath)
    val destFile = new PrintWriter(new File(destPath))
    
    srcDir.listFiles.filter(_.getName.startsWith("part-")).sorted.foreach { file =>
      scala.io.Source.fromFile(file).getLines.foreach(destFile.println)
    }
    destFile.close()
  }
}
