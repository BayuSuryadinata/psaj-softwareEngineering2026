enum MoodType {
  happy,
  sad,
  angry,
  stressed,
  calm,
}

extension MoodExtension on MoodType {
  String get label {
    switch (this) {
      case MoodType.happy:
        return "Senang";
      case MoodType.sad:
        return "Sedih";
      case MoodType.angry:
        return "Marah";
      case MoodType.stressed:
        return "Stress";
      case MoodType.calm:
        return "Tenang";
    }
  }

  String get emoji {
    switch (this) {
      case MoodType.happy:
        return "😄";
      case MoodType.sad:
        return "😢";
      case MoodType.angry:
        return "😡";
      case MoodType.stressed:
        return "😰";
      case MoodType.calm:
        return "😌";
    }
  }
}