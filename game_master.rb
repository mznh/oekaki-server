

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
## ゲーム進行用
  def initialize
    super()
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
    time_thread = timer(3)
    loop do
      event = @event_queue.pop
      case event.type
      when GameEventType::CHALLENGE then
        # userからの回答
        if quiz.check_answer(event.info) then
          # 正解処理
          announce_to_user_group(other,"正解！ 答えは「#{quiz.problem}」でした")
          time_thread.kill 
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
  
  # sec_limit 秒まつ
  # threadオブジェクトを返す
  # 別イベント発生時にそれを停止
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
