use lib 'lib';
use Games::Nex;

use Bailador;
use DBIish;

get '/' => sub {
    my $DATABASE_URL = %*ENV<DATABASE_URL>;
    $DATABASE_URL ~~ /^ 'postgres://'
        $<user>=(\w+) ':' $<password>=(<-[@]>+)
        '@' $<host>=(<-[:]>+) ':' $<port>=(\d+)
        '/' $<database>=(.+) $/
        or die "Couldn't parse DATABASE_URL env variable";

    my ($user, $password, $host, $port, $database) =
        ~$<user>, ~$<password>, ~$<host>, +$<port>, ~$<database>;

    my $dbh = DBIish.connect("Pg", :$host, :$port, :$database, :$user, :$password);

    my $sth = $dbh.prepare(q:to '.');
        SELECT move_data
        FROM Move
        WHERE game_id = 1
        ORDER BY seq_no ASC
        .
    $sth.execute();
    my @moves = $sth.allrows();
    my $game = Games::Nex.from-moves(@moves);

    return q:c:to 'HTML';
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <title>Nex</title>
        </head>
        <body>
            <pre><code>{$game.dump}</code></pre>

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
    my $data = request.env<p6sgi.input>.decode;
    my %params = $data.split('&').map({
        my @components = .split('=');
        @components[0] => @components[1];
    });
    # XXX: input validation
    my $player = %params<player> eq "1" ?? Player1 !! Player2;
    my Pos $own = [+%params<own-stone-row>, +%params<own-stone-column>];
    my Pos $neutral = [+%params<neutral-stone-row>, +%params<neutral-stone-column>];
    my Games::Nex $game .= new(:size(13));
    $game.place(:$player, :$own, :$neutral);

    status(302);
    header("Location", "/");
}

baile( Int(%*ENV<PORT> || 5000) );
