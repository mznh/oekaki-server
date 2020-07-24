

require "./oekaki_action"
require 'json'
require 'thread'

class GameMaster 
  attr_accessor :connection_pool, :paint_log

  def initialize()
    @connection_pool = {}
    ## log はJSONオブジェクトの配列
    @paint_log = []
  end
  def add_connection(user_id, ws)
    @connection_pool[user_id] = ws
  end
  def delete_connection(user_id)
    @connection_pool.delete(user_id)
  end
  ## websocketから裸のデータを受け取りJSONに変換して保存
  def record_log(raw_msg) 
    @paint_log << JSON.parse(raw_msg)
  end
  def clear_log()
    @paint_log = []
  end
  def broadcast_message(msg)
    @connection_pool.each do |k, ws|
      ws.send(JSON.dump(msg))
    end
  end
  def send_log(user_id)
    ws = @connection_pool[user_id]
    @paint_log.each do |msg|
      ws.send(JSON.dump(msg))
    end
  end
  def run()
    Thread.new do
      Thread.pass
      p "new thread start!!!"
      act = OekakiAction.new(ActionType::CLEAR)
      self.broadcast_message(act.to_msg)
      act = OekakiAction.new(ActionType::ANNOUNCE)
      act.message = "ゲームが始まるよ！！！"
      self.broadcast_message(act.to_msg)
      sleep(3)
      act.message = "1 2 3 4"
      self.broadcast_message(act.to_msg)
    end
  end 
end
