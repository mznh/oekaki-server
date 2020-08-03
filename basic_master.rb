

require "./oekaki_action"
require 'json'
require 'thread'

class BasicMaster 
  attr_accessor :connection_pool, :paint_log
  attr_accessor :isPlaying, :nowCorrectAnswer 

  def initialize()
    @connection_pool = {}
    ## log はJSONオブジェクトの配列
    @paint_log = []
    @chat_log = []
    @isPlaying = false
    @event_queue = Queue.new
  end
  ## コネクション管理
  def add_connection(user_id, ws)
    @connection_pool[user_id] = ws
  end
  def delete_connection(user_id)
    @connection_pool.delete(user_id)
  end
  def has_user_ids
    return @connection_pool.keys()
  end
  ## ユーザー管理
  def generate_action_for_send_user_list()
    answer = OekakiAction.new(ActionType::OPERATION)
    ## scoreは仮実装
    res = @connection_pool.values.map{|u| 
      { 
        :userId => u.user_id,
        :userName => u.user_name,
        :userSeat => u.user_seat,
        :score => 100
      }
    }
    answer.message = res.to_json
    answer
  end
  def set_user_name(user_id,user_name)
    seat_num = @connection_pool.length
    @connection_pool[user_id].user_name = user_name
    @connection_pool[user_id].user_seat = seat_num
  end
  def id_to_name(user_id)
    return @connection_pool[user_id].user_name
  end

  # OekakiAction を送信
  def send_action(user_id, act)
    ws = @connection_pool[user_id]
    ws.send(act.to_msg)
  end
  def send_action_to_group(user_id_group, act)
    user_id_group.each do |user_id|
      self.send_action(user_id,act)
    end
  end
  def send_action_broadcast(action)
    self.has_user_ids.each do |user_id|
      self.send_action(user_id,action)
    end
  end
  ## 各種ログは OekakiActionの配列
  # ペイントログ
  def record_paint_log(action) 
    @paint_log << action
  end
  #全消し処理
  def clear_paint_log()
    @paint_log = []
    act = OekakiAction.new(ActionType::CLEAR)
    self.send_action_broadcast(act)
  end
  # チャットログ
  def record_chat_log(action) 
    @chat_log << action
  end
  # 途中参加者へすべてのログを送信
  def send_log(user_id)
    @paint_log.each do |act|
      self.send_action(user_id,act)
    end
    @chat_log.each do |act|
      self.send_action(user_id,act)
    end
  end
  
# アナウンス用メソッド
  def announce_to_user(user_id, str) 
    act = OekakiAction.new(ActionType::ANNOUNCE)
    act.message = str
    send_action(user_id,act)
  end
  def announce_to_user_group(user_id_group, str) 
    act = OekakiAction.new(ActionType::ANNOUNCE)
    act.message = str
    send_action_to_group(user_id_group,act)
  end
  def announce_to_broadcast(str)
    act = OekakiAction.new(ActionType::ANNOUNCE)
    act.message = str
    send_action_broadcast(act)
  end

end
