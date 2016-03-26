use Bailador;

get '/' => sub {
    return q:to 'HTML';
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

            <form action="/game" method="post">
                <label for="placement-player">Player: </label>
                    <input type="text" name="player" id="placement-player"><br>
                <label for="placement-own-stone-row">Own stone row: </label>
                    <input type="text" name="own-stone-row" id="placement-own-stone-row"><br>
                <label for="placement-own-stone-column">Own stone column: </label>
                    <input type="text" name="own-stone-column" id="placement-own-stone-column"><br>
                <label for="placement-neutral-stone-row">Neutral stone row: </label>
                    <input type="text" name="neutral-stone-row" id="placement-neutral-stone-row"><br>
                <label for="placement-neutral-stone-column">Neutral stone column: </label>
                    <input type="text" name="neutral-stone-column" id="placement-neutral-stone-column"><br>
                <input type="submit" value="Send">
            </form>
        </body>
        HTML
}

post '/game' => sub {
    return request.env<p6sgi.input>.decode;
}

baile( Int(%*ENV<PORT> || 5000) );
