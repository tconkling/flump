//
// flump-runtime

package flump.display {

internal class MoviePlayerNode
{
    public var movie :Movie;
    public var player :MoviePlayer;
    public var prev :MoviePlayerNode;
    public var next :MoviePlayerNode;

    public function MoviePlayerNode (movie :Movie, player :MoviePlayer) {
        this.movie = movie;
        this.player = player;
    }
}

}
