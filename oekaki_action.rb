
require 'json'

module ActionType
  WRITE = 0
  CLEAR = 1
  UNDO = 2
  REDO = 3
  OPERATION = 4
  ANNOUNCE = 5
end


class OekakiAction 
  attr_accessor :type, :line, :line_width, :color, :message
  def initialize(type)
    @type = type
    @line = []
    @line_width = 1
    @color = {:red => 0, :green => 0, :blue => 0}
    @message = ""
  end
  def to_msg
    tmp = {
      "actionType" => @type,
      "line" => @line,
      "lineWidht" => @line_width,
      "color" => @color,
      "message" => @message
    }
    return tmp
  end
  def to_json
    return self.to_msg.to_json
  end
end
