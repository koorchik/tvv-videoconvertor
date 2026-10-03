// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TVV Video Converter';

  @override
  String get dropZoneTitle => 'Drop videos or folders here';

  @override
  String get dropZoneHint => 'Your original files are never changed.';

  @override
  String get dropHere => 'Drop to add';

  @override
  String get addVideos => 'Add videos';

  @override
  String get addFolder => 'Add folder';

  @override
  String get yourVideos => 'Your videos';

  @override
  String get clearFinished => 'Clear finished';

  @override
  String get goalTitle => 'What do you want to do?';

  @override
  String get scenarioCompressTitle => 'Make it small';

  @override
  String get scenarioCompressHint =>
      'Looks the same, takes far less space. Good for keeping and for Google Photos.';

  @override
  String get scenarioResolveTitle => 'Edit in DaVinci Resolve';

  @override
  String get scenarioResolveHint =>
      'Makes videos open with picture and sound in Resolve on Linux.';

  @override
  String get presetCompressHevc => 'Works everywhere';

  @override
  String get presetCompressHevcHint =>
      'Plays on phones, TVs, computers and Google Photos.';

  @override
  String get presetCompressAv1 => 'Smallest file';

  @override
  String get presetCompressAv1Hint =>
      'Smaller still, but needs a recent phone, TV or computer to play.';

  @override
  String get presetCompressGpu => 'Fastest';

  @override
  String get presetCompressGpuHint =>
      'Uses the graphics card: much quicker, files a little larger.';

  @override
  String get presetResolveStudio => 'Resolve Studio';

  @override
  String get presetResolveStudioHint =>
      'Usually only the sound needs fixing, which takes seconds.';

  @override
  String get presetResolveFree => 'Free Resolve';

  @override
  String get presetResolveFreeHint =>
      'The picture is converted too. Files become much larger.';

  @override
  String get qualityTitle => 'Quality';

  @override
  String get qualityCompact => 'Smaller file';

  @override
  String get qualityHigh => 'Recommended';

  @override
  String get qualityMaximum => 'Best quality';

  @override
  String get sizeTitle => 'File size';

  @override
  String get sizeSmallest => 'Smallest';

  @override
  String get sizeSmaller => 'Smaller';

  @override
  String get sizeBalanced => 'Recommended';

  @override
  String get sizeBest => 'Best quality';

  @override
  String get convertVideoTitle => 'Also convert the picture';

  @override
  String get convertVideoHint =>
      'Turn on if videos play choppily or show no picture. Needed without an NVIDIA graphics card.';

  @override
  String get saveTitle => 'Where to save';

  @override
  String get saveNextToOriginals =>
      'Next to the originals, in a “Converted” folder';

  @override
  String get saveChooseFolder => 'Change…';

  @override
  String get saveReset => 'Use the default';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Continue';

  @override
  String get trySample => 'Try a 10-second sample';

  @override
  String get sampleFromStart => 'From the beginning';

  @override
  String get sampleFromMiddle => 'From the middle';

  @override
  String get remove => 'Remove';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Try again';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get dragToReorder => 'Drag to change the order';

  @override
  String get statusChecking => 'Checking…';

  @override
  String get statusReadyAsIs => 'Ready as is';

  @override
  String get statusQuickFix => 'Quick, the picture stays untouched';

  @override
  String get statusFullConversion => 'Will be converted';

  @override
  String get statusUnsupported => 'No picture in this file';

  @override
  String get statusUnreadable => 'Not a video file';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusDone => 'Done';

  @override
  String get statusNothingToDo => 'Nothing to do';

  @override
  String get statusFailed => 'Could not convert';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusStarting => 'Starting…';

  @override
  String get noteVariableFrameRate => 'Uneven frame timing will be fixed.';

  @override
  String get noteHevc422 =>
      'This recording format only plays in Resolve with a recent NVIDIA card.';

  @override
  String get noteExperimentalAv1 =>
      'Smallest files are harder to edit smoothly.';

  @override
  String progressLeft(String time) {
    return '$time left';
  }

  @override
  String aboutSize(String size) {
    return 'about $size';
  }

  @override
  String sizeChange(String before, String after) {
    return '$before → $after';
  }

  @override
  String percentSmaller(int percent) {
    return '$percent% smaller';
  }

  @override
  String percentLarger(int percent) {
    return '$percent% larger';
  }

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
    );
    return '$_temp0';
  }

  @override
  String toConvertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos to convert',
      one: '1 video to convert',
      zero: 'Nothing to convert',
    );
    return '$_temp0';
  }

  @override
  String convertingCount(int current, int total) {
    return 'Converting $current of $total';
  }

  @override
  String get allDone => 'All done';

  @override
  String savedSummary(String before, String after) {
    return '$before became $after';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get unitGB => 'GB';

  @override
  String get unitMB => 'MB';

  @override
  String get unitKB => 'KB';

  @override
  String get sampleMaking => 'Making a short sample…';

  @override
  String get sampleReadyTitle => 'Sample ready';

  @override
  String sampleReadyBody(String size, String time) {
    return 'The whole video will be about $size and take about $time.';
  }

  @override
  String get sampleFailed => 'The sample could not be made.';

  @override
  String get playSample => 'Play sample';

  @override
  String get playOriginal => 'Play original';

  @override
  String get close => 'Close';

  @override
  String get details => 'Details';

  @override
  String get engineMissingTitle => 'The video engine is missing';

  @override
  String get engineMissingBody =>
      'This app needs FFmpeg to convert videos, and could not find it. Install FFmpeg and start the app again.';

  @override
  String get startingUp => 'Getting ready…';

  @override
  String get quitTitle => 'Stop converting and quit?';

  @override
  String get quitBody =>
      'The video being converted will be discarded. Finished videos are kept.';

  @override
  String get quit => 'Quit';

  @override
  String get keepConverting => 'Keep converting';

  @override
  String get more => 'More';

  @override
  String get showCommand => 'Show the command';

  @override
  String get commandTitle => 'The command for this video';

  @override
  String get commandIntro =>
      'This is what the app runs for this video. Copy it to run it yourself in a terminal, or to adjust it.';

  @override
  String get commandOneLine => 'One line';

  @override
  String get commandExplained => 'Explained';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get moreOptions => 'More options';

  @override
  String get optionCodecTitle => 'Editing format';

  @override
  String get cmdHideBanner => 'Do not print version information';

  @override
  String get cmdSeek => 'Start from this point of the video, in seconds';

  @override
  String get cmdInput => 'The video to convert';

  @override
  String get cmdLength => 'Convert only this many seconds';

  @override
  String get cmdKeepPicture => 'Take the picture from the original';

  @override
  String get cmdKeepSound => 'Take every sound track, if there are any';

  @override
  String get cmdNoPicture => 'Leave the picture out';

  @override
  String get cmdNoSound => 'Leave the sound out';

  @override
  String get cmdKeepMetadata => 'Keep dates, titles and timecode';

  @override
  String get cmdDropMetadata => 'Remove dates, titles and other details';

  @override
  String get cmdPictureCopy => 'Picture: copy as it is, no quality loss';

  @override
  String get cmdPictureEncoder => 'Picture: re-encode with this encoder';

  @override
  String get cmdSoundCopy => 'Sound: copy as it is';

  @override
  String get cmdSoundEncoder => 'Sound: convert to this format';

  @override
  String get cmdSpeedPreset =>
      'Effort: slower makes a smaller file at the same quality';

  @override
  String get cmdQuality =>
      'Quality target (for most encoders a lower number means better quality and a bigger file)';

  @override
  String get cmdProfile => 'Variant of the format';

  @override
  String get cmdEncoderTuning => 'Fine tuning of the encoder';

  @override
  String get cmdPixelFormat => 'Colour precision of the picture';

  @override
  String get cmdFilter => 'Processing applied to the picture';

  @override
  String get cmdSoundBitrate => 'Sound quality, as data per second';

  @override
  String get cmdConstantFrameRate => 'Make the frame timing even';

  @override
  String get cmdFrameRate => 'Frames per second';

  @override
  String get cmdKeyframeInterval =>
      'A complete frame at least this often, for smooth scrubbing';

  @override
  String get cmdPlayerTag =>
      'Label that lets Apple players recognise the video';

  @override
  String get cmdFastStart =>
      'Put the index first, so playback can start while downloading';

  @override
  String get cmdContainer => 'File type of the result';

  @override
  String get cmdOutput => 'Where the result is written';

  @override
  String get scenarioShareTitle => 'Send to a phone';

  @override
  String get scenarioShareHint =>
      'Small and plays on any phone, in Telegram and other messengers. In Telegram, send it as a file to keep this quality.';

  @override
  String get scenarioAudioTitle => 'Get the sound';

  @override
  String get scenarioAudioHint =>
      'Saves the sound of a video as a separate file.';

  @override
  String get scenarioPrivacyTitle => 'Remove personal details';

  @override
  String get scenarioPrivacyHint =>
      'Removes the hidden notes about place, date, camera and author before you share a video. What is seen and heard stays the same.';

  @override
  String get scenarioRemuxTitle => 'Change file type';

  @override
  String get scenarioRemuxHint =>
      'Puts the video into another kind of file in seconds, without touching the picture quality.';

  @override
  String get optionSizeTitle => 'Size';

  @override
  String get shareSmall => 'Smaller';

  @override
  String get shareStandard => 'Standard';

  @override
  String get optionFormatTitle => 'File type';

  @override
  String get formatOriginal => 'As it is';

  @override
  String get optionModeTitle => 'How thoroughly';

  @override
  String get modeQuick => 'Quick';

  @override
  String get modeThorough => 'Thorough';

  @override
  String get modeThoroughHint =>
      'Thorough rebuilds the picture and sound from scratch. It takes much longer and is the safest.';

  @override
  String get noteHdrToneMapped =>
      'Very bright colours will be adjusted to look right on any screen.';

  @override
  String get noteHdrNotConverted =>
      'This video uses extra-bright colours that may look washed out on a phone.';

  @override
  String get noteAudioConvertedToFit =>
      'The sound will be converted to fit this file type.';

  @override
  String get statusNoSound => 'No sound in this file';

  @override
  String get statusCannotHold => 'This file type cannot hold this video';

  @override
  String get estimating => 'measuring size…';

  @override
  String takesAbout(String time) {
    return 'takes about $time';
  }

  @override
  String goalForSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'What to do with the $count selected videos?',
      one: 'What to do with the selected video?',
    );
    return '$_temp0';
  }

  @override
  String get backToAll => 'Back to all videos';

  @override
  String get goalAppliesToAll =>
      'Applies to all videos. Click a video to choose something different for it.';

  @override
  String get addAgain => 'Add again for another goal';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Same as the computer';

  @override
  String get techPictureCopied => 'picture copied as is';

  @override
  String get techSoundCopied => 'sound copied as is';

  @override
  String get techNoSound => 'no sound';

  @override
  String get techNoReencode => 'no re-encoding';

  @override
  String techUpTo(String lines) {
    return 'up to $lines';
  }
}
