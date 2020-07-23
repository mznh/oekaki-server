

require "./oekaki_action"

class GameMaster 
  attr_accessor :connection_pool, :log

  def initialize()
    @connection_pool = {}
    @log = []
  end
  def add_connection(user_id, ws)
    @connection_pool[user_id] = ws
  end
  def delete_connection(user_id)
    @connection_pool.delete(user_id)
  end
  def record_log(msg) 
    @log << msg
  end
  def clear_log()
    @log = []
  end
  def broadcast_message(action)
    @connection_pool.each do |k, ws|
      ws.send(action.to_json)
    end
  end
end
