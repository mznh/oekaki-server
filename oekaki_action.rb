
require 'json'

module ActionType
  WRITE = 0
  CLEAR = 1
  UNDO = 2
  REDO = 3
  OPERATION = 4
  ANNOUNCE = 5
  CHAT = 6
end


class OekakiAction 
  attr_accessor :type, :line, :line_width, :color, :user_name, :message
  def initialize(type)
      @type = type
      @user_name = ""
      @line = []
      @line_width = 1
      @color = {:red => 0, :green => 0, :blue => 0}
      @message = ""
  end
  def self.newFromJSON(json)
    act = OekakiAction.new(json["actionType"])
    act.line =  json["line"]
    act.line_width = json["lineWidth"]
    act.color = json["color"]
    act.user_name = json["userName"]
    act.message = json["message"]
    return act
  end
  def to_msg
    tmp = {
      "actionType" => @type,
      "line" => @line,
      "lineWidth" => @line_width,
      "color" => @color,
      "userName" => @user_name,
      "message" => @message
    }
    return JSON.dump(tmp)
  end
  def to_json
    return self.to_msg.to_json
  end
end


class OekakiProblem
  attr_accessor :problem, :answer_list
  def initialize(prob,ans_list)
    @problem = prob
    @answer_list = ans_list
  end
  def check_answer(challenge)
    return @answer_list.include? challenge
  end
end
