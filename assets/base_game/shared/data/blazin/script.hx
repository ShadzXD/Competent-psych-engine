function onCreatePost()
{
    for (noteStrum in game.opponentStrums) 
        noteStrum.x = -400;
}
function onCreate()
{
   game.useMiddleScroll = true;
}