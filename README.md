Daniel Zuerbig
Music And Engineering
Homework Assignment 3
MIDI Decoder


Code works by running the hw3.m file. The GUI shows a few midi files that are included in the /midi folder placed in the same directory as the rest of the code. In order to play your own midi file, simply place a .mid file in the /midi folder, and change the choice = 18 switch case statement to open midi/FILENAME.mid

The code first parses the whole midi file to locate all notes in the song, and then creates a player object containing all the notes in the song, in a noteArray. Then, the playAudio function is envoked, which then accesses the notes in the array and plays the appropriate one. A drum line was made with a different FM model, and new envelope generators were instatiated to accomodate them. Drum lines are known because they are on channel 9. 

In order to improve performance with longer songs, the synth object was altered to only loop through 200 notes at a time. This required changing the way the objEnv objects keep their own time. Instead, the synth object is the only object keeping time, and it passes this down through all subsequent objects, (osc, env). Having this fix makes it possible to listen to much longer songs than those provided, try out one of the Zelda songs, or even the Super Smash Bros Theme. 

The testscript.m file can be used to test out the instruments before playing a full song. Simply set the inst constant, and run the code.

Many commands are recognized by the code, but ignored, such as patch, pitch bend, and other meta commands. I prioritized a fully working song and other features, before adding smaller special effects. 

Two extra functions were added, called vlb_find and find_note. vlb_find searches from the current index, and both parses out the delta t value, but also informs the main program how long the vlb was. This way, the main function can increment its counter to right after the vlb. The find_note command looks through the song matrix and identifies a note with the provided midi number, that was turned on, but not turned off, and returns it's index. This way, the program can turn on multiple notes, and then off multiple notes, withouth loosing track. 