use Bailador;
get '/' => sub {
    "hello world"
}
baile( Int(%*ENV<PORT> || 5000) );
