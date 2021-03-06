describe Gamefic::Plot::Snapshot do
  it "saves entities" do
    plot = Gamefic::Plot.new
    plot.make Gamefic::Entity, name: 'entity'
    snapshot = plot.save
    expect(snapshot[:entities].length).to eq(1)
  end

  it "restores entities" do
    plot = Gamefic::Plot.new
    entity = plot.make Gamefic::Entity, name: 'old name'
    snapshot = plot.save
    entity.name = 'new name'
    plot.restore snapshot
    expect(entity.name).to eq('old name')
  end

  it "saves subplots" do
    plot = Gamefic::Plot.new
    plot.branch Gamefic::Subplot
    snapshot = plot.save
    expect(snapshot[:subplots].length).to eq(1)
  end

  it "restores subplots" do
    plot = Gamefic::Plot.new
    subplot = plot.branch Gamefic::Subplot
    snapshot = plot.save
    subplot.conclude
    expect(subplot.concluded?).to be(true)
    plot.restore snapshot
    expect(plot.subplots.length).to eq(1)
    expect(plot.subplots[0].concluded?).to be(false)
  end

  it "restores dynamic entities" do
    plot = Gamefic::Plot.new
    plot.make Gamefic::Entity, name: 'static entity'
    plot.ready
    plot.make Gamefic::Entity, name: 'dynamic entity'
    snapshot = plot.save
    plot.restore snapshot
    expect(plot.entities.length).to eq(2)
    expect(plot.entities[1].name).to eq('dynamic entity')
  end

  it "restores a player" do
    plot = Gamefic::Plot.new
    player = plot.cast Actor, name: 'old name'
    plot.introduce player
    snapshot = plot.save
    player.name = 'new name'
    plot.restore snapshot
    expect(plot.players.length).to eq(1)
    expect(plot.players[0].name).to eq('old name')
  end

  it "restores a hash in an entity session" do
    plot = Gamefic::Plot.new
    entity = plot.make Entity, name: 'entity'
    hash = { one: 'one', two: 'two' }
    entity[:hash] = hash
    snapshot = plot.save
    entity[:hash] = nil
    plot.restore snapshot
    expect(entity[:hash]).to eq(hash)
  end
end
