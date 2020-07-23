

require "./oekaki_action"
require 'json'

class GameMaster 
  attr_accessor :connection_pool, :log

  def initialize()
    @connection_pool = {}
    ## log はJSONオブジェクトの配列
    @log = []
  end
  def add_connection(user_id, ws)
    @connection_pool[user_id] = ws
  end
  def delete_connection(user_id)
    @connection_pool.delete(user_id)
  end
  ## websocketから裸のデータを受け取りJSONに変換して保存
  def record_log(raw_msg) 
    @log << JSON.parse(raw_msg)
  end
  def clear_log()
    @log = []
  end
  def broadcast_message(msg)
    @connection_pool.each do |k, ws|
      ws.send(JSON.dump(msg))
    end
  end
  def send_log(user_id)
    ws = @connection_pool[user_id]
    @log.each do |msg|
      ws.send(JSON.dump(msg))
    end
  end
end
