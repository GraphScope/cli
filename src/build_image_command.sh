echo "# this file is located in 'src/build_image_command.sh'"
echo "# code for 'gs build-image' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args
image_name=${args[image]}

log "image to be built: ${image_name}"