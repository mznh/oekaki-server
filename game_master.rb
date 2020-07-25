

require "./oekaki_action"
require 'json'
require 'thread'



module GameEventType
  CHALLENGE = 0
  TIMEUP = 1
end

class GameEvent
  attr_accessor :type, :user_id, :info
  def initialize(type, user_id, info)
    @type = type
    @user_id = user_id
    @info = info
  end
end

class GameMaster 
  attr_accessor :connection_pool, :paint_log
  attr_accessor :isPlaying, :nowCorrectAnswer 

  def initialize()
    @connection_pool = {}
    ## log はJSONオブジェクトの配列
    @paint_log = []
    @isPlaying = false
    @event_queue = Queue.new
  end
  def add_connection(user_id, ws)
    @connection_pool[user_id] = ws
  end
  def delete_connection(user_id)
    @connection_pool.delete(user_id)
  end
  def has_user_ids
    return @connection_pool.keys()
  end
  def send_action(user_id, act)
    ws = @connection_pool[user_id]
    ws.send(act.to_msg)
  end
  def send_action_to_group(user_id_group, act)
    user_id_group.each do |user_id|
      self.send_action(user_id,act)
    end
  end
  ## OekakiActionクラスの配列
  def record_log(action) 
    @paint_log << action
  end
  def broadcast_message(action)
    self.has_user_ids.each do |user_id|
      self.send_action(user_id,action)
    end
  end
  def clear_log()
    @paint_log = []
    act = OekakiAction.new(ActionType::CLEAR)
    self.broadcast_message(act)
  end
  def send_log(user_id)
    @paint_log.each do |act|
      self.send_action(user_id,act)
    end
  end

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
  ## user_id が answerと答えた
  def challenge_answer(user_id,answer)
    @event_queue.push(GameEvent.new(GameEventType::CHALLENGE,user_id,answer))
  end

  def game_start()
    Thread.new do
      @isPlaying = true
      Thread.pass
      p "new thread start!!!"
      clear_log()
      act = OekakiAction.new(ActionType::ANNOUNCE)
      act.message = "ゲームが始まるよ！！！"
      broadcast_message(act)
      play( OekakiProblem.new("にんじん",["にんじん","にんじーん"]))
      @isPlaying = false
    end
  end 

  def play(quiz)
    ## 出題者決める
    act = OekakiAction.new(ActionType::CLEAR)
    broadcast_message(act)
    drawer = @connection_pool.keys.sample
    other = @connection_pool.keys - [drawer]
    announce_to_user(drawer,"あなたは描き手です！")
    announce_to_user_group(other,"あなたは回答者です！")
    sleep(1)
    announce_to_user(drawer,quiz.problem)

    # 時間計測スタート
    time_thread = timer(20)
    loop do
      event = @event_queue.pop
      case event.type
      when GameEventType::CHALLENGE then
        puts "答えられた #{event.info}" 
        if quiz.check_answer(event.info) then
          # 正解処理
          announce_to_user_group(other,"正解！！！！")
          time_thread.kill 
        end
      when GameEventType::TIMEUP then
        puts "時間切れでございます" 
        # loopから抜ける 
        break
      else
        p "unknown data !!!!!  "
      end
    end
  end
  
  # sec_limit 秒まつ
  # threadオブジェクトを返す
  # 別イベント発生時にそれを停止
  def timer( sec_limit )
    return Thread.new do
      sec_limit.times.reverse_each do |i|
        sleep(1) 
        announce_to_user_group(self.has_user_ids,"timer:#{i}")
      end
      ## 時間切れ処理
      announce_to_user_group(self.has_user_ids,"Time Up !!!")
      ## 雑に文字列
      @event_queue.push GameEvent.new(GameEventType::TIMEUP,"GameMaster","")
    end
  end
end
