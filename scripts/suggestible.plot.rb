class Gamefic::Suggestions
  def current
    @current ||= []
  end

  def future
    @future ||= []
  end

  def update
    current.clear
    current.concat future
    puts current.join(',')
    future.clear
  end

  def clear
    current.clear
    future.clear
  end
end

module Gamefic::Suggestible
  def suggestions
    @suggestions ||= Gamefic::Suggestions.new
  end

  def suggest command
    suggestions.future.push command unless suggestions.future.include? command
  end
end

class Gamefic::Character
  include Suggestible
  serialize :suggestions
end

on_ready do
  players.each { |player|
    if player.scene == :active or player.next_scene == :active
      player.suggestions.update
    else
      player.suggestions.clear
    end
  }
end

respond :suggest do |actor|
  actor.stream '<ul>'
  actor.suggestions.current.sort.each { |s|
    actor.stream "<li>#{s}</li>"
  }
  actor.stream '</ul>'
end
