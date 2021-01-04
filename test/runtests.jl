using MenuAdventures
using MenuAdventures:
    Box,
    Car,
    Clothes,
    Door,
    Food,
    Key,
    Lamp,
    OrderedDict,
    Person,
    Room,
    StickyThing,
    Table,
    TakeOff,
    terminal,
    TTYTerminal
using Documenter: doctest
using DelimitedFiles: readdlm, writedlm
using Test: @test

# set to true to generate a new testing transcript
GENERATE = false

cd(joinpath(pkgdir(MenuAdventures), "test"))

function make_test_universe(; interactive = false)
    you = Person(
        name = "matilda",
        grammatical_person = second_person,
        description = "a little worse for the wear",
    )
    bob = Person(
        name = "Bob",
        dialog = OrderedDict("Hello" => Answer("Hello", () -> nothing), "Goodbye" => Answer("Goodbye", () -> nothing))
    )
    A = Room(name = "A", description = "A non-descript room", indefinite_article = "")
    B = Room(name = "B"; providing_light = false)
    C = Room(name = "C")
    you = Person(
        name = "matilda",
        grammatical_person = second_person,
        description = "a little worse for the wear",
    )
    yellow_key = Key(name = "yellow key", description = "It's yellow, duh!")
    yellow_box = Box(name = "yellow box")
    red_key = Key(name = "red key")
    lamp = Lamp(name = "lamp")
    yellow_door = Door(
        name = "yellow door",
        key = yellow_key,
        description = "What color do you thing this is?",
    )
    yellow_car = Car(name = "car")
    table = Table(name = "blue table")
    hat = Clothes(name = "hat")
    apple = Food(name = "apple")
    gum = StickyThing(name = "gum")
    output = IOBuffer()
    universe = Universe(
        you,
        introduction = "Welcome!",
        interface = 
            if interactive
                terminal
            else
                TTYTerminal("unix", stdin, output, stderr)
            end
    )
    universe[A, you] = containing
    universe[A, bob] = containing
    universe[A, yellow_car] = containing
    universe[A, table] = containing
    universe[A, hat] = containing
    universe[A, apple] = containing
    universe[A, gum] = containing
    universe[B, yellow_box] = containing
    universe[yellow_box, yellow_key] = containing
    universe[yellow_box, red_key] = containing
    universe[A, lamp] = containing
    universe[A, B] = north
    universe[A, C] = yellow_door, west
    universe[C, Room(name = "D")] = north_east
    universe[C, Room(name = "E")] = south_west
    universe[C, Room(name = "F")] = south
    universe[C, Room(name = "G")] = south_east
    universe[A, Room(name = "H")] = east
    universe[C, Room(name = "I")] = up 
    universe[C, Room(name = "J")] = down
    universe[C, Room(name = "K")] = inside
    universe[C, Room(name = "L")] = outside
    universe[C, Room(name = "M")] = north_west
    universe
end

const KEY_PRESS = Dict(:up => "\e[A", :down => "\e[B", :enter => "\r")

function test_turn_sequence(universe, option_numbers)
    for option_number in option_numbers
        for _ in 1:(option_number - 1)
            write(stdin.buffer, KEY_PRESS[:down])
        end
        write(stdin.buffer, KEY_PRESS[:enter])
    end
    turn!(universe; introduce = true)
    String(take!(universe.interface.out_stream))
end

if GENERATE
    universe = make_test_universe(; interactive = true)
    choices_log = universe.choices_log
    turn!(universe; introduce = true)
    open("choices_log.txt", "w") do io
        writedlm(io, universe.choices_log)
    end
    open("transcript.txt", "w") do io
        # TODO: avoid allocation
        write(io, test_turn_sequence(make_test_universe(), choices_log))
    end
else
    doctest(MenuAdventures)
    choices_log = readdlm("choices_log.txt")
    @test test_turn_sequence(make_test_universe(), choices_log) == read("transcript.txt", String)
end

# make sure to lock and unlock with the wrong key
# open an empty box
# look around to get both open/closed and locked/unlocked
# push between rooms
# go onto
# give
# attach