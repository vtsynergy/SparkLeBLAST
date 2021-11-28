/* Partitioning And Formatting BLAST database on a Spark Cluster*/
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


object SparkLeMakeDB {
  val hdfsAddr = "/home/karimy";
  def main(args: Array[String]) {
  val conf2 = new SparkConf().setAppName("SparkLeMakeDB")
    val sc = new SparkContext(conf2)
    val splits = args(0)
    val conf = new Configuration
    
    /* Set delimiter to split file in correct local*/
    conf.set("textinputformat.record.delimiter", "\n>")
    val filePath = args(1)
    var script = args(2)
    val dbName = args(3)
    val dbType = args(4)

    /* Read database into an RDD*/
    val dataset = sc.newAPIHadoopFile(filePath, classOf[TextInputFormat], classOf[LongWritable], classOf[Text],conf)
   
    /* Repartition according to number of partitions specified by user */
    val finalData = dataset.map( d => (">" + d._2).trim().replaceAll("\u0001"," ")).repartition(splits.toInt);
    dataset.unpersist();    

    
    /* construct db specifications file ( for correct e-value computation in search phase ) */
    val dbGenomes = finalData.map( sequence => getGenome(sequence.toString));
    val dbSizes = dbGenomes.map(seq => seq.length().longValue());
    var count: Long = dbSizes.count();
    var length: Long = dbSizes.reduce(_ + _);
    var dbsOutput = length + "\n" + count + "\n";  

    
    /* save partitions */
    finalData.saveAsTextFile(dbName);
    // finalData.unpersist();
    
    
    /* write db specifications file */
    val fs = FileSystem.get(sc.hadoopConfiguration);
    val output = fs.create(new Path(dbName + "/database.dbs"));
    val os = new BufferedOutputStream(output);
    os.write(dbsOutput.getBytes("UTF-8"))
    os.close()   

    
    
    // map partition with index
    val mapped =   finalData.mapPartitionsWithIndex{
                        // 'index' represents the Partition No
                        // 'iterator' to iterate through all elements
                        //                         in the partition
                        (index, iterator) => {
                           val myList = iterator.toList.slice(0,1)
                           var parName = getPartitionNumber(index)
                           myList.map(x => parName).iterator
                        }
                     }
    //end map partition with index
    
    // pass db path as argument to formatting script
    script = script + " " + dbName + " " + dbType

    
    try{  
        mapped.pipe(script).saveAsTextFile(dbName + "_formatting_logs");
    }
    catch {
      case e : Exception => { println("WARNING: NOT ALL PARTITIONS FORMATTED DUE TO: " + e) };
    } 
    mapped.saveAsTextFile(dbName + "_partitionsIDs");
    sc.stop
    }

    def delHDFS(hdConf: Configuration, path: String): Unit = {
    try{
      val hdfs = FileSystem.get(new URI(hdfsAddr), hdConf);
      hdfs.delete(new Path(path), true);
    }
    catch {
      case e : Exception => { println("Error HDFS exception" + e) };
    }
  }
  def getPartitionNumber(index: Int): String = {
        var leadingZeros = "0";
        if ( index < 10 )
            leadingZeros = "0000";
        else if ( index < 100 )
           leadingZeros = "000";
        else if ( index < 10000 )
           leadingZeros = "00";
        else if ( index < 100000 )
           leadingZeros = "0";
        else
           leadingZeros = "";
        return "part-" + leadingZeros + index;
  }

  def getGenome(record: String): String = {
    val sep = record.indexOf("\n");
    val genome = record.drop(sep).replaceAll("\n", "").replaceAll("[()]","");
    return genome;
  }

}
