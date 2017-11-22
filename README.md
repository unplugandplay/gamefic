# Gamefic

A Ruby Interactive Fiction Framework

Gamefic is a system for developing and playing adventure games.

# Installation

Game authors should install the Gamefic SDK:

    gem install gamefic-sdk

The SDK includes the core Gamefic gem that game engines use to run plots.

# The Gamefic Executable

The `gamefic` executable provides commands for creating, testing, and building games. A list of commands is available via `gamefic help`.

## Using Gamefic in Development

The examples in this README assume you are working with the executables that
get distributed with the gems. If you're actively developing the core Gamefic
libraries, you'll want the executables to use the repo instead. Use bundle to
configure the environment:

    cd /path/to/repo
    bundle install

Then use bundle exec to run the binary:

    bundle exec gamefic

# Running the Examples

The Git repo includes several demo games in the examples directory. You can
run them from the command line like so:

    gamefic test examples/[name]

One of the examples is a Gamefic implementation of [Cloak of Darkness](http://www.firthworks.com/roger/cloak/),
courtesy of Peter Orme:

    gamefic test examples/cloak_of_darkness

# Game Commands

The Gamefic library provides a collection of commands that are common in most
text adventures, including the following:

    go [north, south, west, east]
    look [item]
    get [item]
    inventory
    drop [item]

It also implements common synonyms; for example, any of the following work the
same as "get book":

    take book
    pick up book
    pick book up

## Command Shortcuts

The common directions you can go--north, south, west, east, up, and down--can
be shortened to their first letter. For example, "n" means "go north."
Additionally, northwest, northeast, southwest, and southeast can be referenced
as nw, ne, sw, and se respectively.

Some other shortcuts:

    i = inventory
	x or exam = look (examine)

# Writing Your First Game

The easiest way to start your own game is with the init command:

    gamefic init mygame

Gamefic will create a directory called "mygame" that contains the main script
and an import directory. The game is already capable of running:

    gamefic test mygame

Right now the game is just a single featureless room. Open the mygame/main.rb
file in a text editor. Modify it to the following:

    script 'standard'

    apartment = make Room, :name => "apartment", :description => "You are in a tiny one-room apartment."

    introduction do |player|
        player.parent = apartment
	end

Run the script from the command line:

    gamefic test mygame

The script will drop you into a game prompt. There's still not much you can do
except look around:

    > look
	*Apartment*
	You are in a tiny one-room apartment.
	>

We can make things a little more interesting by putting something in the
apartment. Add this code to main.rb:

    pencil = make Item, :name => "a pencil", :description => "A plain old No. 2 yellow.", :parent => apartment

Play the script again. Now the apartment contains an item you can manipulate.

	> look
	Apartment
	You are in a tiny one-room apartment.
	You see a pencil.
	> look at pencil
	A plain old No. 2 yellow.
	> take pencil
	You take the pencil.
	> inventory
	pencil
	> drop pencil
	You drop the pencil.
	> quit

## The Script Code

Let's take a closer look at the methods we used in the script.

### script

The script method in plot scripts is similar to Ruby's require method. It loads
a script from your game's scripts directory. If the script doesn't exist locally,
the program will look for it in shared libraries.

The "standard" library provides a bunch of functionality common to text
adventures, including the abilities to look around, move between rooms, and
pick up objects.

### make

The make method adds an entity to your story. In this demo, we added two types
of entities: a Room and an Item. The first argument is the entity type and the
second is an object containing the entity's properties. Note that one of the
pencil's properties is parent, which is set to the apartment.

### introduction

The introduction method accepts a proc that will be executed when the game
begins. In this example, it just puts the player in the room, but it could
also output an introductory message:

    player.tell "Welcome to your cozy little apartment!"

### Entity Types

We've created two types of entities for this demo, a Room and an Item. These
are likely the most common entity types you'll use while creating a game, but
there are several others defined in the standard library. Here's a brief
explanation of each:

#### Container

An entity that can contain other items. Typically, anything that a player can
carry (i.e., an Item) can be put inside a Container.

#### Fixture

A stationary object, such as a large piece of furniture. Fixtures are included
in a room's list of visible items, but players cannot pick them up.

#### Item

Something that players can carry.

#### Portal

A fixed Entity that players can use to travel from Room to Room. Typically, a
Portal is named for the direction it represents, eg., north, south, west, etc.

#### Room

A location that players and other Entities can occupy.

#### Scenery

An Entity that can provide a description when players "look" at it. Unlike
Fixtures, Scenery is not included in a room's list of visible items.

## Adding More Entities

Let's explore some of the other Entity types by adding more stuff to the demo.

    bed = make Fixture, :name => "bed", :description => "A comfy little twin bed.", :parent => apartment
	
    cupboard = make Container, :name => "cupboard", :description => "A small wooden cupboard.", :parent => apartment

    closet = make Room, :name => "closet", :description => "This closet is surprisingly spacious for such a small apartment."
    connect closet, apartment, "east"

Run the demo again and try interacting with the new Entities. Among the new
actions you can perform are walking into the closet ("west" from the apartment)
and putting the pencil in the cupboard.

## Connecting Rooms

Note the additional line of code following the creation of the closet:

    connect closet, apartment, "east"

The connect method creates a Portal between this Room and another. The first
argument is the Room to be connected and the second argument is the name of the
Portal. By default, the connect method creates another Portal in the
destination Room that leads back to this one. In this case, the apartment will
have a Portal named "west" that leads to the closet. The names that can be used
for bidirectional Portals are north, south, west, east, up, northwest,
northeast, southwest, southeast, up, and down.

## Actions

Now let's try making a new action for players to perform. Add the following
code to the demo:

    respond :lie_on, Query::Siblings.new(bed) do |actor, bed|
	    actor.tell "You take a short nap. That was refreshing!"
	end

Now there's a new command you can use in the game.

    > lie on bed
    You take a short nap. That was refreshing!

How does all that code work? Bear with me, because this gets a little weird.

### The Command Symbol

The first argument to the action method is the symbol used to identify it.
In this case, the symbol is :lie_on. The game engine translates the underscore
into a space, so the player can invoke this action by entering "lie on."

### The Query Object

The second argument in our example is a Query object that the game's command
parser uses to identify an Entity in the game. The Query::Siblings class
searches the player's siblings, i.e., the other Entities in the Room.

Additional arguments to the Query object filter the scope of Entities that
trigger the Action. In this case, bed means that the Action can only be
performed on the bed. If the player references any other Entity (e.g., "lie on
cupboard"), the Action's proc will not be executed.

### Types of Queries

Different Query classes have different rules for filtering the entities that
are available to the Action.

* Query::Reachable is perhaps the most useful type of query. It will return all
  the entities that players can reach, including things in the room, things in
  their inventory, things supported by other things in the room, and things
  inside the room's open containers.

* Query::Visible returns everything available from Query::Reachable plus the
  things that are visible without being reachable, such as things that are in a
  closed transparent container.

* Query::Children returns the subject's children, i.e., the player's inventory.

* Query::Siblings returns the parent entity's other children.

* Query::Text returns whatever plain text was parsed from the command. Unlike
  typical queries that produce an Entity, the argument that results from a
  Query::Text is a String.

### The Action's Proc

The final argument is the proc to execute in response to the player's command.
The proc's first argument is always the player Entity. The remaining arguments
are the Entities returned by each Query.

This example's proc code simply sends a message to the player via the tell method.

## Syntaxes

Right now, the only way for the player to lie on the bed is to enter "lie on
bed." What if the player words it differently?

    > lie down on bed
    I don't know what you mean by 'lie down on bed.'

Trying to guess the exact phrasing the game expects can be frustrating. To
keep your game fun and immersive, it's a good idea to support multiple
Syntaxes for actions. We can make "lie down" work with the following line of
code:

    interpret "lie down on :thing", "lie on :thing"

This code tells the game to accept a Syntax that matches "lie down on :thing"
where :thing is a placeholder for a Query. The action the Syntax executes
is :lie_on. The remainder of the arguments tell the game how to order the
placeholders when executing the Action's proc. In this case, the only
placeholder is :thing.

Now "lie down on" works the same as "lie on":

    > lie down on bed
    You take a short nap. That was refreshing!

Here are a couple more syntaxes that might prove useful:

    interpret "sleep on :thing", "lie on :thing"
	interpret "sleep", "lie on bed"

The first Syntax allows the player to enter "sleep on bed."

The second Syntax is a little different. If the player simply enters "sleep"
without specifying where, the Syntax assumes that the argument to pass to the
Action should be "bed."

    > sleep
    You take a short nap. That was refreshing!

Great! But what if there's not a bed around?

	> go west
	You go west.
	Closet
	Obvious exits: east
	> sleep
	I don't know what you mean by 'sleep.'

That's just about the correct behavior we want: the player needs to
be near a bed to sleep. Unfortunately, the game's response is a little
misleading: "I don't know what you mean by 'sleep.'" It actually knows what
sleep means, but only if there's a bed in the room. Without a bed, the game
will never execute the lie_on Action.

Let's fix this with another Action:

	respond :sleep do |actor|
		if actor.parent.children.that_are(bed).length > 0
			actor.perform "lie on bed"
		else
			actor.tell "There's not a bed in here."
		end
	end

This Action will let the player sleep as long as he's in the room with the bed
in it. We can add a few more Syntaxes like so:

	interpret "go to sleep", "sleep"
	interpret "rest", "sleep"
	interpret "snooze", "sleep"

# Building Game Files

Once you're happy with your game, you can compile it into a .gfic file for
distribution:

    gfk build mygame

This will create a file called mygame.gfic in mygame/release that you can share
with other Gamefic users.

# More Information

Go to [the official Gamefic website](http://gamefic.com) for games, news, and
more documentation.
