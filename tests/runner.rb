APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__) + "/.."))
["extras","bin","worker","lib"].each { |x| $LOAD_PATH.unshift(EVAL_APP_ROOT + "/#{x}")}

WORKER_ROOT = APP_ROOT + "/worker"

require "packet"

