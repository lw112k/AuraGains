import 'package:image_picker/image_picker.dart';

// Maps to your post_type_enum
enum PostType { normal, askExpert }

// Maps to your visibility_type_enum
enum PostVisibility { public, friends, private }

// Maps to your media_type_enum
enum MediaType { picture, video, text }

// Maps to your tag_type_enum
enum TagType { system, user }

class SelectedMedia {
  final XFile file;
  final MediaType type;

  SelectedMedia({required this.file, required this.type});
}

class SelectedTag {
  final int? tagId; // Null if it's a brand new custom tag
  final String name;
  final TagType type;

  SelectedTag({this.tagId, required this.name, required this.type});
}

class CreatePostModel {
  String title;
  String description;
  PostType postType;
  PostVisibility visibility;
  List<SelectedMedia> mediaList;
  List<SelectedTag> tags;
  XFile? thumbnailImage; 

  CreatePostModel({
    this.title = '',
    this.description = '',
    this.postType = PostType.normal,
    this.visibility = PostVisibility.public,
    List<SelectedMedia>? mediaList,
    List<SelectedTag>? tags,
    this.thumbnailImage,
  }) : mediaList = mediaList ?? [], 
       tags = tags ?? []; 
}
