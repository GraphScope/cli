echo "# this file is located in 'src/spark_classpath_command.sh'"
echo "# code for 'gs spark-classpath' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args

# TODO(zhanglei): generate a file named ~/.graphscope_4spark.env

# check if the file exists
# if yes, raise a warning
# otherwise, generate a new 

echo "$(green_bold "Generated environment variables for spark jobs in ~/.graphscope_4spark.env")"
echo
echo "export the env to your bash terminal by running: source ~/.graphscope_4spark.env"