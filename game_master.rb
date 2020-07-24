

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
    act = OekakiAction.new(ActionType::CLEAR)
    self.broadcast_message(act.to_msg)
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
  def send_action(user_id,act)
    ws = @connection_pool[user_id]
    ws.send(JSON.dump(act.to_msg))
  end
  def announce_to_user(user_id, str) 
    act = OekakiAction.new(ActionType::ANNOUNCE)
    act.message = str
    self.send_action(user_id,act)
  end
  def game_start()
    Thread.new do
      Thread.pass
      p "new thread start!!!"
      act = OekakiAction.new(ActionType::CLEAR)
      self.broadcast_message(act.to_msg)
      act = OekakiAction.new(ActionType::ANNOUNCE)
      act.message = "ゲームが始まるよ！！！"
      self.broadcast_message(act.to_msg)
      drawer = @connection_pool.keys.sample
      other = @connection_pool.keys - [drawer]
      self.announce_to_user(drawer,"あなたは描き手です！")
      other.each do |user_id|
        self.announce_to_user(user_id,"あなたは回答者です！")
      end
    end
  end 
end
