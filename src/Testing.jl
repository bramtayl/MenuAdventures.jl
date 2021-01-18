"""
    MenuAdventures.Testing

A sub-module for testing your universe.

```jldoctest
julia> using MenuAdventures

julia> using MenuAdventures.Testing

julia> @universe struct Universe <: AbstractUniverse
        end;

julia> @noun struct Room <: AbstractRoom
            already_lit::Bool = true
        end;

julia> @noun struct Person <: Noun
        end;

julia> function make_universe(interface)
            you = Person(
                "Brandon",
                grammatical_person = second_person,
                indefinite_article = "",
            )
            universe = Universe(you, interface = interface)
            universe[Room("room"), you] = Containing()
            universe
        end;

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "Testing")) do
            check_choices(make_universe)
        end
Conflict in line 6
Existing transcript: " > [control]quit[control]"
New transcript: " > [control]Quit[control]"
false

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "Testing")) do
            check_choices(make_universe, transcript_file = "transcript2.txt")
        end
Conflict in line 6
Existing transcript: ""
New transcript: " > [control]Quit[control]"
false

julia> cd(joinpath(pkgdir(MenuAdventures), "test", "Testing")) do
            check_choices(make_universe, transcript_file = "transcript3.txt")
        end
Conflict in line 7
Existing transcript: " more"
New transcript: ""
false
```
"""
module Testing

using DelimitedFiles: readdlm, writedlm
using MenuAdventures: AbstractUniverse, terminal, TTYTerminal, turn!

const KEY_PRESS = Dict(:up => "\e[A", :down => "\e[B", :enter => "\r")

function run_turn_sequence(io, choices_log)
    for option_number in choices_log
        for _ in 1:(option_number - 1)
            write(io, KEY_PRESS[:down])
        end
        write(io, KEY_PRESS[:enter])
    end
end

"""
    save_choices(make_universe;
        choices_file = "choices.txt", 
        transcript_file = "transcript.txt",
        resume = false
    )

Save the choices a user makes as a delimited file, as well as the transcript of the game.

Use to create a transcript to test with [`check_choices`](@ref).
`make_universe` should be a function which takes one argument, an IO interface, and returns an [`AbstractUniverse`](@ref).
`choices_file` will be the delimited file where user choices are saved.
`transcript_file` will be the file where the game transcript will be saved.
If `resume` is true, the game will pick up from the point you left off, based on the existing `choices_file`.
"""
function save_choices(make_universe;
    choices_file = "choices.txt", 
    transcript_file = "transcript.txt",
    resume = false
)
    take!(stdin.buffer)
    if resume
        run_turn_sequence(stdin.buffer, readdlm(choices_file))
    end
    universe = make_universe(terminal)
    choices_log = universe.choices_log
    turn!(universe)
    open(
        io -> writedlm(io, choices_log),
        choices_file,
        if resume
            "a"
        else
            "w"
        end
    )
    open(transcript_file, "w") do transcript
        take!(stdin.buffer)
        run_turn_sequence(stdin.buffer, choices_log)
        universe = make_universe(TTYTerminal("unix", stdin, transcript, stderr))
        turn!(universe)
    end
end

function find_line_difference(string1, string2)
    lines1 = split(string1, '\n')
    lines2 = split(string2, '\n')
    for (line_number, (line1, line2)) in enumerate(zip(lines1, lines2))
        if line1 != line2
            return line_number, line1, line2
        end
    end
    number_of_lines1 = length(lines1)
    number_of_lines2 = length(lines2)
    if number_of_lines2 > number_of_lines1
        next_line = number_of_lines1 + 1
        return next_line, "", lines2[next_line]
    elseif number_of_lines1 > number_of_lines2
        next_line = number_of_lines2 + 1
        return next_line, lines1[next_line], ""
    else
        return nothing
    end
end

export save_choices

function replace_escape_codes(text)
    replace(
        text,
        r"\x1b\[([\x30-\x3F]*)([\x20-\x2F]*)([\x40-\x7E])" =>
        s"[control]"
    )
end
                
"""
    check_choices(make_universe;
        choices_file = "choices.txt", 
        transcript_file = "transcript.txt"
    )

Check the results of choices against a transcript created with [`save_choices`](@ref).

Return `true` if the results match, `false` otherwise.
`make_universe` should be a function which takes one argument, an IO interface, and returns an [`AbstractUniverse`].
`choices_file` will be the delimited file where user choices were saved.
`transcript_file` will be the file where the game transcript was saved.

"""
function check_choices(make_universe;
    choices_file = "choices.txt", 
    transcript_file = "transcript.txt"
)
    output = IOBuffer()
    take!(stdin.buffer)
    universe = make_universe(TTYTerminal("unix", stdin, output, stderr))
    run_turn_sequence(stdin.buffer, readdlm(choices_file))
    turn!(universe)
    old_result = read(transcript_file, String)
    new_result = String(take!(output))
    matches = old_result == new_result
    difference = find_line_difference(old_result, new_result)
    the_same = difference === nothing
    if !the_same
        line_number, expected_line, received_line = difference
        print("Conflict in line ")
        println(line_number)
        print("Existing transcript: ")
        show(replace_escape_codes(expected_line))
        println()
        print("New transcript: ")
        show(replace_escape_codes(received_line))
        println()
    end
    the_same
end

export check_choices

end