

require "./basic_master"



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


$test_problem_set =[
  OekakiProblem.new("にんじん",["にんじん","にんじーん"]),
  OekakiProblem.new("りんご",["りんご","ringo"]),
  OekakiProblem.new("ほうれんそう",["ほうれんそう","ほっほっほほうれんそう"])
]


class GameMaster < BasicMaster
  def initialize
    super()
  end

  ## 各種ログは OekakiActionの配列
  # ペイントログ
  def record_paint_log(action) 
    @paint_log << action
  end
  # 全消し処理
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
  
  ## user_id が answerと答えた
  def challenge_answer(user_id,answer)
    @event_queue.push(GameEvent.new(GameEventType::CHALLENGE,user_id,answer))
  end


  ## ユーザーのスコア変動等を通知　
  def broadcast_player_status()
    act = generate_action_for_send_user_list
    send_action_broadcast(act)
  end

  def game_start()
    Thread.new do
      @isPlaying = true
      Thread.pass
      p "new thread start!!!"
      clear_paint_log()
      announce_to_broadcast("ゲームがはじまるよ")
      $test_problem_set.each do|quiz|
        play(quiz)
        sleep(3)
      end
      announce_to_broadcast("ゲーム終了")
      @isPlaying = false
    end
  end 

  def play(quiz)
    # 画面消去
    clear_paint_log()
    ## 出題者決める
    drawer = @connection_pool.keys.sample
    other = @connection_pool.keys - [drawer]
    announce_to_user(drawer,"あなたは描き手です！")
    announce_to_user_group(other,"あなたは回答者です！")
    sleep(1)
    # 問題通知
    announce_to_user(drawer,quiz.problem)
    announce_to_user_group(other,"何が描かれたか ひらがな で回答してね")
    # 時間計測スタート
    @event_queue.clear
    time_thread = timer(30)
    loop do
      event = @event_queue.pop
      case event.type
      when GameEventType::CHALLENGE then
        # userからの回答
        if quiz.check_answer(event.info) then
          # 正解処理
          announce_to_user_group(other,"正解！ 答えは「#{quiz.problem}」でした")
          # 得点加算
          change_user_score(event.user_id, 100)
          # 得点通知
          broadcast_player_status
          time_thread.kill 
          break
        end
      when GameEventType::TIMEUP then
        # 時間切れ
        announce_to_broadcast("時間切れ・・・正解は「#{quiz.problem}」でした")
        p "time up"
        # loopから抜ける 
        break
      else
        p "unknown data error"
        p event
      end
    end
  end
  
  # sec_limit 秒カウントダウンする
  # threadオブジェクトを返す
  # 別イベント発生時にそれを停止させる
  def timer(sec_limit)
    return Thread.new do
      sec_limit.times.reverse_each do |i|
        sleep(1) 
        announce_to_user_group(self.has_user_ids,"timer:#{i}")
      end
      ## 時間切れ処理
      announce_to_user_group(self.has_user_ids,"Time Up !!!")
      @event_queue.push GameEvent.new(GameEventType::TIMEUP,"GameMaster","")
    end
  end
end
