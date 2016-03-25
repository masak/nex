use Games::Nex;

sub emptyGame(Int $size) is export {
    return Games::Nex.new(:$size);
}
