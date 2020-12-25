public struct User {
    /*int64 album_count;
    string bio;
    string	cover_photo;
    int64 followee_count;
    int64 follower_count;
    string handle;*/
    string id;
    /*bool is_verified;
    string location;*/
    string name;
    /*int64 playlist_count;
    int64 repost_count;*/
    int64 track_count;
}
public struct Track_Artwork {
    string img_150x150;
    //string img_480x480;
    //string img_1000x1000;
}
public struct Track {
    Track_Artwork artwork;
    string id;
    /*string mood;
    string release_date;
    string remix_parent_id;
    int64 repost_count;
    int64 favorite_count;
    string tags;
    string description;
    string genre;*/
    int64 duration;
    /*bool downloadable;
    int64 play_count;*/
    string title;
    User user;
}

// Wait.. this isn't how you do debugging
const bool DEBUG = false;