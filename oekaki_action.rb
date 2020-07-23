
require 'json'

module ActionType
  WRITE = 0
  CLEAR = 1
  UNDO = 2
  REDO = 3
  OPERATION = 4
end


class OekakiAction 
  attr_accessor :type, :line, :line_width, :color, :message
  def initialize(type)
    @type = type
  end
  def to_json
  end
end
