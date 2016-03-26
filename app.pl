use Bailador;

get '/' => sub {
    return q:to'HTML';
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <title>Nex</title>
        </head>
        <body>
            <pre><code>. . . . . . . . . . . . .
         . . . . . . . . . . . . .
          . . . . . . . . . . . . .
           . . . . . . . . . . . . .
            . . . . . . . . . . . . .
             . . . . . . . . . . . . .
              . . . . . . . . . . . . .
               . . . . . . . . . . . . .
                . . . . . . . . . . . . .
                 . . . . . . . . . . . . .
                  . . . . . . . . . . . . .
                   . . . . . . . . . . . . .
                    . . . . . . . . . . . . .</code></pre>

            <form action="//game" method="post">
                <label for="placement-player">Player: </label>
                    <input type="text" id="placement-player"><br>
                <label for="placement-own-stone-row">Own stone row: </label>
                    <input type="text" id="placement-own-stone-row"><br>
                <label for="placement-own-stone-column">Own stone column: </label>
                    <input type="text" id="placement-own-stone-column"><br>
                <label for="placement-own-stone-row">Own stone row: </label>
                    <input type="text" id="placement-own-stone-row"><br>
                <label for="placement-own-stone-column">Own stone column: </label>
                    <input type="text" id="placement-own-stone-column"><br>
                <input type="submit" value="Send">
            </form>
        </body>
        HTML
}

baile( Int(%*ENV<PORT> || 5000) );
