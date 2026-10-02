import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// Application name shown in the window title.
  ///
  /// In en, this message translates to:
  /// **'TVV Video Converter'**
  String get appTitle;

  /// No description provided for @dropZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop videos or folders here'**
  String get dropZoneTitle;

  /// No description provided for @dropZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Your original files are never changed.'**
  String get dropZoneHint;

  /// No description provided for @dropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop to add'**
  String get dropHere;

  /// No description provided for @addVideos.
  ///
  /// In en, this message translates to:
  /// **'Add videos'**
  String get addVideos;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get addFolder;

  /// No description provided for @yourVideos.
  ///
  /// In en, this message translates to:
  /// **'Your videos'**
  String get yourVideos;

  /// No description provided for @clearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get clearFinished;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get goalTitle;

  /// No description provided for @scenarioCompressTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it small'**
  String get scenarioCompressTitle;

  /// No description provided for @scenarioCompressHint.
  ///
  /// In en, this message translates to:
  /// **'Looks the same, takes far less space. Good for keeping and for Google Photos.'**
  String get scenarioCompressHint;

  /// No description provided for @scenarioResolveTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit in DaVinci Resolve'**
  String get scenarioResolveTitle;

  /// No description provided for @scenarioResolveHint.
  ///
  /// In en, this message translates to:
  /// **'Makes videos open with picture and sound in Resolve on Linux.'**
  String get scenarioResolveHint;

  /// No description provided for @presetCompressHevc.
  ///
  /// In en, this message translates to:
  /// **'Works everywhere'**
  String get presetCompressHevc;

  /// No description provided for @presetCompressHevcHint.
  ///
  /// In en, this message translates to:
  /// **'Plays on phones, TVs, computers and Google Photos.'**
  String get presetCompressHevcHint;

  /// No description provided for @presetCompressAv1.
  ///
  /// In en, this message translates to:
  /// **'Smallest file'**
  String get presetCompressAv1;

  /// No description provided for @presetCompressAv1Hint.
  ///
  /// In en, this message translates to:
  /// **'Smaller still, but needs a recent phone, TV or computer to play.'**
  String get presetCompressAv1Hint;

  /// No description provided for @presetCompressGpu.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get presetCompressGpu;

  /// No description provided for @presetCompressGpuHint.
  ///
  /// In en, this message translates to:
  /// **'Uses the graphics card: much quicker, files a little larger.'**
  String get presetCompressGpuHint;

  /// No description provided for @presetResolveStudio.
  ///
  /// In en, this message translates to:
  /// **'Resolve Studio'**
  String get presetResolveStudio;

  /// No description provided for @presetResolveStudioHint.
  ///
  /// In en, this message translates to:
  /// **'Usually only the sound needs fixing, which takes seconds.'**
  String get presetResolveStudioHint;

  /// No description provided for @presetResolveFree.
  ///
  /// In en, this message translates to:
  /// **'Free Resolve'**
  String get presetResolveFree;

  /// No description provided for @presetResolveFreeHint.
  ///
  /// In en, this message translates to:
  /// **'The picture is converted too. Files become much larger.'**
  String get presetResolveFreeHint;

  /// No description provided for @qualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get qualityTitle;

  /// No description provided for @qualityCompact.
  ///
  /// In en, this message translates to:
  /// **'Smaller file'**
  String get qualityCompact;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get qualityHigh;

  /// No description provided for @qualityMaximum.
  ///
  /// In en, this message translates to:
  /// **'Best quality'**
  String get qualityMaximum;

  /// No description provided for @sizeTitle.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get sizeTitle;

  /// No description provided for @sizeSmallest.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get sizeSmallest;

  /// No description provided for @sizeSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get sizeSmaller;

  /// No description provided for @sizeBalanced.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sizeBalanced;

  /// No description provided for @sizeBest.
  ///
  /// In en, this message translates to:
  /// **'Best quality'**
  String get sizeBest;

  /// No description provided for @convertVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Also convert the picture'**
  String get convertVideoTitle;

  /// No description provided for @convertVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on if videos play choppily or show no picture. Needed without an NVIDIA graphics card.'**
  String get convertVideoHint;

  /// No description provided for @saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to save'**
  String get saveTitle;

  /// No description provided for @saveNextToOriginals.
  ///
  /// In en, this message translates to:
  /// **'Next to the originals, in a “Converted” folder'**
  String get saveNextToOriginals;

  /// No description provided for @saveChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get saveChooseFolder;

  /// No description provided for @saveReset.
  ///
  /// In en, this message translates to:
  /// **'Use the default'**
  String get saveReset;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get resume;

  /// No description provided for @trySample.
  ///
  /// In en, this message translates to:
  /// **'Try a 10-second sample'**
  String get trySample;

  /// No description provided for @sampleFromStart.
  ///
  /// In en, this message translates to:
  /// **'From the beginning'**
  String get sampleFromStart;

  /// No description provided for @sampleFromMiddle.
  ///
  /// In en, this message translates to:
  /// **'From the middle'**
  String get sampleFromMiddle;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to change the order'**
  String get dragToReorder;

  /// No description provided for @statusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get statusChecking;

  /// No description provided for @statusReadyAsIs.
  ///
  /// In en, this message translates to:
  /// **'Ready as is'**
  String get statusReadyAsIs;

  /// No description provided for @statusQuickFix.
  ///
  /// In en, this message translates to:
  /// **'Quick, the picture stays untouched'**
  String get statusQuickFix;

  /// No description provided for @statusFullConversion.
  ///
  /// In en, this message translates to:
  /// **'Will be converted'**
  String get statusFullConversion;

  /// No description provided for @statusUnsupported.
  ///
  /// In en, this message translates to:
  /// **'No picture in this file'**
  String get statusUnsupported;

  /// No description provided for @statusUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Not a video file'**
  String get statusUnreadable;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusNothingToDo.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do'**
  String get statusNothingToDo;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not convert'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get statusStarting;

  /// No description provided for @noteVariableFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Uneven frame timing will be fixed.'**
  String get noteVariableFrameRate;

  /// No description provided for @noteHevc422.
  ///
  /// In en, this message translates to:
  /// **'This recording format only plays in Resolve with a recent NVIDIA card.'**
  String get noteHevc422;

  /// No description provided for @noteExperimentalAv1.
  ///
  /// In en, this message translates to:
  /// **'Smallest files are harder to edit smoothly.'**
  String get noteExperimentalAv1;

  /// No description provided for @progressLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String progressLeft(String time);

  /// No description provided for @aboutSize.
  ///
  /// In en, this message translates to:
  /// **'about {size}'**
  String aboutSize(String size);

  /// No description provided for @sizeChange.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String sizeChange(String before, String after);

  /// No description provided for @percentSmaller.
  ///
  /// In en, this message translates to:
  /// **'{percent}% smaller'**
  String percentSmaller(int percent);

  /// No description provided for @percentLarger.
  ///
  /// In en, this message translates to:
  /// **'{percent}% larger'**
  String percentLarger(int percent);

  /// No description provided for @videoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 video} other{{count} videos}}'**
  String videoCount(int count);

  /// No description provided for @toConvertCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to convert} =1{1 video to convert} other{{count} videos to convert}}'**
  String toConvertCount(int count);

  /// No description provided for @convertingCount.
  ///
  /// In en, this message translates to:
  /// **'Converting {current} of {total}'**
  String convertingCount(int current, int total);

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get allDone;

  /// No description provided for @savedSummary.
  ///
  /// In en, this message translates to:
  /// **'{before} became {after}'**
  String savedSummary(String before, String after);

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String durationSeconds(int seconds);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHours(int hours, int minutes);

  /// No description provided for @unitGB.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get unitGB;

  /// No description provided for @unitMB.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get unitMB;

  /// No description provided for @unitKB.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get unitKB;

  /// No description provided for @sampleMaking.
  ///
  /// In en, this message translates to:
  /// **'Making a short sample…'**
  String get sampleMaking;

  /// No description provided for @sampleReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample ready'**
  String get sampleReadyTitle;

  /// No description provided for @sampleReadyBody.
  ///
  /// In en, this message translates to:
  /// **'The whole video will be about {size} and take about {time}.'**
  String sampleReadyBody(String size, String time);

  /// No description provided for @sampleFailed.
  ///
  /// In en, this message translates to:
  /// **'The sample could not be made.'**
  String get sampleFailed;

  /// No description provided for @playSample.
  ///
  /// In en, this message translates to:
  /// **'Play sample'**
  String get playSample;

  /// No description provided for @playOriginal.
  ///
  /// In en, this message translates to:
  /// **'Play original'**
  String get playOriginal;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @engineMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'The video engine is missing'**
  String get engineMissingTitle;

  /// No description provided for @engineMissingBody.
  ///
  /// In en, this message translates to:
  /// **'This app needs FFmpeg to convert videos, and could not find it. Install FFmpeg and start the app again.'**
  String get engineMissingBody;

  /// No description provided for @startingUp.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get startingUp;

  /// No description provided for @quitTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop converting and quit?'**
  String get quitTitle;

  /// No description provided for @quitBody.
  ///
  /// In en, this message translates to:
  /// **'The video being converted will be discarded. Finished videos are kept.'**
  String get quitBody;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @keepConverting.
  ///
  /// In en, this message translates to:
  /// **'Keep converting'**
  String get keepConverting;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @showCommand.
  ///
  /// In en, this message translates to:
  /// **'Show the command'**
  String get showCommand;

  /// No description provided for @commandTitle.
  ///
  /// In en, this message translates to:
  /// **'The command for this video'**
  String get commandTitle;

  /// No description provided for @commandIntro.
  ///
  /// In en, this message translates to:
  /// **'This is what the app runs for this video. Copy it to run it yourself in a terminal, or to adjust it.'**
  String get commandIntro;

  /// No description provided for @commandOneLine.
  ///
  /// In en, this message translates to:
  /// **'One line'**
  String get commandOneLine;

  /// No description provided for @commandExplained.
  ///
  /// In en, this message translates to:
  /// **'Explained'**
  String get commandExplained;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @optionCodecTitle.
  ///
  /// In en, this message translates to:
  /// **'Editing format'**
  String get optionCodecTitle;

  /// No description provided for @cmdHideBanner.
  ///
  /// In en, this message translates to:
  /// **'Do not print version information'**
  String get cmdHideBanner;

  /// No description provided for @cmdSeek.
  ///
  /// In en, this message translates to:
  /// **'Start from this point of the video, in seconds'**
  String get cmdSeek;

  /// No description provided for @cmdInput.
  ///
  /// In en, this message translates to:
  /// **'The video to convert'**
  String get cmdInput;

  /// No description provided for @cmdLength.
  ///
  /// In en, this message translates to:
  /// **'Convert only this many seconds'**
  String get cmdLength;

  /// No description provided for @cmdKeepPicture.
  ///
  /// In en, this message translates to:
  /// **'Take the picture from the original'**
  String get cmdKeepPicture;

  /// No description provided for @cmdKeepSound.
  ///
  /// In en, this message translates to:
  /// **'Take every sound track, if there are any'**
  String get cmdKeepSound;

  /// No description provided for @cmdNoPicture.
  ///
  /// In en, this message translates to:
  /// **'Leave the picture out'**
  String get cmdNoPicture;

  /// No description provided for @cmdNoSound.
  ///
  /// In en, this message translates to:
  /// **'Leave the sound out'**
  String get cmdNoSound;

  /// No description provided for @cmdKeepMetadata.
  ///
  /// In en, this message translates to:
  /// **'Keep dates, titles and timecode'**
  String get cmdKeepMetadata;

  /// No description provided for @cmdDropMetadata.
  ///
  /// In en, this message translates to:
  /// **'Remove dates, titles and other details'**
  String get cmdDropMetadata;

  /// No description provided for @cmdPictureCopy.
  ///
  /// In en, this message translates to:
  /// **'Picture: copy as it is, no quality loss'**
  String get cmdPictureCopy;

  /// No description provided for @cmdPictureEncoder.
  ///
  /// In en, this message translates to:
  /// **'Picture: re-encode with this encoder'**
  String get cmdPictureEncoder;

  /// No description provided for @cmdSoundCopy.
  ///
  /// In en, this message translates to:
  /// **'Sound: copy as it is'**
  String get cmdSoundCopy;

  /// No description provided for @cmdSoundEncoder.
  ///
  /// In en, this message translates to:
  /// **'Sound: convert to this format'**
  String get cmdSoundEncoder;

  /// No description provided for @cmdSpeedPreset.
  ///
  /// In en, this message translates to:
  /// **'Effort: slower makes a smaller file at the same quality'**
  String get cmdSpeedPreset;

  /// No description provided for @cmdQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality target (for most encoders a lower number means better quality and a bigger file)'**
  String get cmdQuality;

  /// No description provided for @cmdProfile.
  ///
  /// In en, this message translates to:
  /// **'Variant of the format'**
  String get cmdProfile;

  /// No description provided for @cmdEncoderTuning.
  ///
  /// In en, this message translates to:
  /// **'Fine tuning of the encoder'**
  String get cmdEncoderTuning;

  /// No description provided for @cmdPixelFormat.
  ///
  /// In en, this message translates to:
  /// **'Colour precision of the picture'**
  String get cmdPixelFormat;

  /// No description provided for @cmdFilter.
  ///
  /// In en, this message translates to:
  /// **'Processing applied to the picture'**
  String get cmdFilter;

  /// No description provided for @cmdSoundBitrate.
  ///
  /// In en, this message translates to:
  /// **'Sound quality, as data per second'**
  String get cmdSoundBitrate;

  /// No description provided for @cmdConstantFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Make the frame timing even'**
  String get cmdConstantFrameRate;

  /// No description provided for @cmdFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Frames per second'**
  String get cmdFrameRate;

  /// No description provided for @cmdKeyframeInterval.
  ///
  /// In en, this message translates to:
  /// **'A complete frame at least this often, for smooth scrubbing'**
  String get cmdKeyframeInterval;

  /// No description provided for @cmdPlayerTag.
  ///
  /// In en, this message translates to:
  /// **'Label that lets Apple players recognise the video'**
  String get cmdPlayerTag;

  /// No description provided for @cmdFastStart.
  ///
  /// In en, this message translates to:
  /// **'Put the index first, so playback can start while downloading'**
  String get cmdFastStart;

  /// No description provided for @cmdContainer.
  ///
  /// In en, this message translates to:
  /// **'File type of the result'**
  String get cmdContainer;

  /// No description provided for @cmdOutput.
  ///
  /// In en, this message translates to:
  /// **'Where the result is written'**
  String get cmdOutput;

  /// No description provided for @scenarioShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to a phone'**
  String get scenarioShareTitle;

  /// No description provided for @scenarioShareHint.
  ///
  /// In en, this message translates to:
  /// **'Small and plays on any phone, in Telegram and other messengers. In Telegram, send it as a file to keep this quality.'**
  String get scenarioShareHint;

  /// No description provided for @scenarioAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Get the sound'**
  String get scenarioAudioTitle;

  /// No description provided for @scenarioAudioHint.
  ///
  /// In en, this message translates to:
  /// **'Saves the sound of a video as a separate file.'**
  String get scenarioAudioHint;

  /// No description provided for @scenarioPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove personal details'**
  String get scenarioPrivacyTitle;

  /// No description provided for @scenarioPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Removes the hidden notes about place, date, camera and author before you share a video. What is seen and heard stays the same.'**
  String get scenarioPrivacyHint;

  /// No description provided for @scenarioRemuxTitle.
  ///
  /// In en, this message translates to:
  /// **'Change file type'**
  String get scenarioRemuxTitle;

  /// No description provided for @scenarioRemuxHint.
  ///
  /// In en, this message translates to:
  /// **'Puts the video into another kind of file in seconds, without touching the picture quality.'**
  String get scenarioRemuxHint;

  /// No description provided for @optionSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get optionSizeTitle;

  /// No description provided for @shareSmall.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get shareSmall;

  /// No description provided for @shareStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get shareStandard;

  /// No description provided for @optionFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'File type'**
  String get optionFormatTitle;

  /// No description provided for @formatOriginal.
  ///
  /// In en, this message translates to:
  /// **'As it is'**
  String get formatOriginal;

  /// No description provided for @optionModeTitle.
  ///
  /// In en, this message translates to:
  /// **'How thoroughly'**
  String get optionModeTitle;

  /// No description provided for @modeQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get modeQuick;

  /// No description provided for @modeThorough.
  ///
  /// In en, this message translates to:
  /// **'Thorough'**
  String get modeThorough;

  /// No description provided for @modeThoroughHint.
  ///
  /// In en, this message translates to:
  /// **'Thorough rebuilds the picture and sound from scratch. It takes much longer and is the safest.'**
  String get modeThoroughHint;

  /// No description provided for @noteHdrToneMapped.
  ///
  /// In en, this message translates to:
  /// **'Very bright colours will be adjusted to look right on any screen.'**
  String get noteHdrToneMapped;

  /// No description provided for @noteHdrNotConverted.
  ///
  /// In en, this message translates to:
  /// **'This video uses extra-bright colours that may look washed out on a phone.'**
  String get noteHdrNotConverted;

  /// No description provided for @noteAudioConvertedToFit.
  ///
  /// In en, this message translates to:
  /// **'The sound will be converted to fit this file type.'**
  String get noteAudioConvertedToFit;

  /// No description provided for @statusNoSound.
  ///
  /// In en, this message translates to:
  /// **'No sound in this file'**
  String get statusNoSound;

  /// No description provided for @statusCannotHold.
  ///
  /// In en, this message translates to:
  /// **'This file type cannot hold this video'**
  String get statusCannotHold;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
