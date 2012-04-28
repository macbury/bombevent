require 'logging'
require 'player'
require 'game'
require 'events'

class Client
  include Logging

  def initialize(game, websocket)
    info("New connection")
    @game, @websocket = game, websocket
    @player = Player.new(game)
    @game.add_player(@player)
    send_event Events::MyPlayerId.new(@player)
    @player.send_position
    @game.subscribe { |event| send_event(event) }
    websocket.onmessage { |msg| process_message(msg) }
  end

  def process_message(msg)
    debug("Recieved message: #{msg}")
    events = Events::Base.parse(msg)
    events.each { |event| process_event(event) }
  end

  def process_event(event)
    case event
    when Events::Move
      @player.move(event.direction)
    when Events::Delete
      # TODO
    when Events::LoadMap
      events = @game.game_objects.map do |object|
        Events::Position.new object
      end
      send_events(events)
    end
  end

  def send_event(event)
    debug("Send event: #{Array(event).to_json}")
    @websocket.send(Array(event).to_json)
  end
end
