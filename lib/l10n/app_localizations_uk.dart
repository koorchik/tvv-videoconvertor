// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'TVV Відеоконвертер';

  @override
  String get dropZoneTitle => 'Перетягніть сюди відео або папки';

  @override
  String get dropZoneHint => 'Оригінальні файли ніколи не змінюються.';

  @override
  String get dropHere => 'Відпустіть, щоб додати';

  @override
  String get addVideos => 'Додати відео';

  @override
  String get addFolder => 'Додати папку';

  @override
  String get yourVideos => 'Ваші відео';

  @override
  String get clearFinished => 'Прибрати готові';

  @override
  String get goalTitle => 'Що потрібно зробити?';

  @override
  String get scenarioCompressTitle => 'Зменшити розмір';

  @override
  String get scenarioCompressHint =>
      'Виглядає так само, займає значно менше місця. Добре для зберігання та Google Фото.';

  @override
  String get scenarioResolveTitle => 'Монтувати в DaVinci Resolve';

  @override
  String get scenarioResolveHint =>
      'Щоб відео відкривалися в Resolve на Linux із зображенням і звуком.';

  @override
  String get presetCompressHevc => 'Працює всюди';

  @override
  String get presetCompressHevcHint =>
      'Відтворюється на телефонах, телевізорах, комп’ютерах і в Google Фото.';

  @override
  String get presetCompressAv1 => 'Найменший файл';

  @override
  String get presetCompressAv1Hint =>
      'Ще менший, але потребує нового телефона, телевізора чи комп’ютера.';

  @override
  String get presetCompressGpu => 'Найшвидше';

  @override
  String get presetCompressGpuHint =>
      'Використовує відеокарту: значно швидше, файли трохи більші.';

  @override
  String get presetResolveStudio => 'Resolve Studio';

  @override
  String get presetResolveStudioHint =>
      'Зазвичай треба виправити лише звук, це займає секунди.';

  @override
  String get presetResolveFree => 'Безкоштовний Resolve';

  @override
  String get presetResolveFreeHint =>
      'Зображення теж конвертується. Файли стають значно більшими.';

  @override
  String get qualityTitle => 'Якість';

  @override
  String get qualityCompact => 'Менший файл';

  @override
  String get qualityHigh => 'Рекомендовано';

  @override
  String get qualityMaximum => 'Найкраща якість';

  @override
  String get sizeTitle => 'Розмір файлу';

  @override
  String get sizeSmallest => 'Найменший';

  @override
  String get sizeSmaller => 'Менший';

  @override
  String get sizeBalanced => 'Рекомендовано';

  @override
  String get sizeBest => 'Найкраща якість';

  @override
  String get convertVideoTitle => 'Конвертувати також зображення';

  @override
  String get convertVideoHint =>
      'Увімкніть, якщо відео гальмує або немає зображення. Потрібно без відеокарти NVIDIA.';

  @override
  String get saveTitle => 'Куди зберегти';

  @override
  String get saveNextToOriginals => 'Поруч з оригіналами, у папці «Converted»';

  @override
  String get saveChooseFolder => 'Змінити…';

  @override
  String get saveReset => 'Як за замовчуванням';

  @override
  String get start => 'Почати';

  @override
  String get stop => 'Зупинити';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продовжити';

  @override
  String get trySample => 'Спробувати на 10 секундах';

  @override
  String get sampleFromStart => 'З початку';

  @override
  String get sampleFromMiddle => 'Із середини';

  @override
  String get remove => 'Прибрати';

  @override
  String get cancel => 'Скасувати';

  @override
  String get retry => 'Спробувати ще раз';

  @override
  String get showInFolder => 'Показати в папці';

  @override
  String get dragToReorder => 'Перетягніть, щоб змінити порядок';

  @override
  String get statusChecking => 'Перевірка…';

  @override
  String get statusReadyAsIs => 'Уже готове';

  @override
  String get statusQuickFix => 'Швидко, зображення не змінюється';

  @override
  String get statusFullConversion => 'Буде конвертовано';

  @override
  String get statusUnsupported => 'У цьому файлі немає зображення';

  @override
  String get statusUnreadable => 'Це не відеофайл';

  @override
  String get statusPaused => 'Пауза';

  @override
  String get statusDone => 'Готово';

  @override
  String get statusNothingToDo => 'Нічого робити не треба';

  @override
  String get statusFailed => 'Не вдалося конвертувати';

  @override
  String get statusCancelled => 'Скасовано';

  @override
  String get statusStarting => 'Запуск…';

  @override
  String get noteVariableFrameRate =>
      'Нерівномірну частоту кадрів буде виправлено.';

  @override
  String get noteHevc422 =>
      'Цей формат запису відтворюється в Resolve лише з новою відеокартою NVIDIA.';

  @override
  String get noteExperimentalAv1 => 'Найменші файли важче плавно монтувати.';

  @override
  String progressLeft(String time) {
    return 'залишилось $time';
  }

  @override
  String aboutSize(String size) {
    return 'приблизно $size';
  }

  @override
  String sizeChange(String before, String after) {
    return '$before → $after';
  }

  @override
  String percentSmaller(int percent) {
    return 'на $percent% менше';
  }

  @override
  String percentLarger(int percent) {
    return 'на $percent% більше';
  }

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count відео',
      many: '$count відео',
      few: '$count відео',
      one: '$count відео',
    );
    return '$_temp0';
  }

  @override
  String toConvertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count відео до конвертації',
      many: '$count відео до конвертації',
      few: '$count відео до конвертації',
      one: '$count відео до конвертації',
      zero: 'Нічого конвертувати',
    );
    return '$_temp0';
  }

  @override
  String convertingCount(int current, int total) {
    return 'Конвертація $current з $total';
  }

  @override
  String get allDone => 'Усе готово';

  @override
  String savedSummary(String before, String after) {
    return '$before стало $after';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes хв';
  }

  @override
  String durationHours(int hours, int minutes) {
    return '$hours год $minutes хв';
  }

  @override
  String get unitGB => 'ГБ';

  @override
  String get unitMB => 'МБ';

  @override
  String get unitKB => 'КБ';

  @override
  String get sampleMaking => 'Готуємо короткий зразок…';

  @override
  String get sampleReadyTitle => 'Зразок готовий';

  @override
  String sampleReadyBody(String size, String time) {
    return 'Усе відео займатиме приблизно $size, конвертація триватиме приблизно $time.';
  }

  @override
  String get sampleFailed => 'Не вдалося зробити зразок.';

  @override
  String get playSample => 'Переглянути зразок';

  @override
  String get playOriginal => 'Переглянути оригінал';

  @override
  String get close => 'Закрити';

  @override
  String get details => 'Подробиці';

  @override
  String get engineMissingTitle => 'Немає відеорушія';

  @override
  String get engineMissingBody =>
      'Для конвертації потрібен FFmpeg, але його не знайдено. Встановіть FFmpeg і запустіть програму знову.';

  @override
  String get startingUp => 'Підготовка…';

  @override
  String get quitTitle => 'Зупинити конвертацію і вийти?';

  @override
  String get quitBody =>
      'Відео, яке зараз конвертується, буде відкинуто. Готові відео залишаться.';

  @override
  String get quit => 'Вийти';

  @override
  String get keepConverting => 'Продовжити конвертацію';

  @override
  String get more => 'Більше';

  @override
  String get showCommand => 'Показати команду';

  @override
  String get commandTitle => 'Команда для цього відео';

  @override
  String get commandIntro =>
      'Саме це програма виконує для цього відео. Скопіюйте, щоб запустити самостійно в терміналі або змінити.';

  @override
  String get commandOneLine => 'Один рядок';

  @override
  String get commandExplained => 'З поясненнями';

  @override
  String get copy => 'Копіювати';

  @override
  String get copied => 'Скопійовано';

  @override
  String get moreOptions => 'Більше налаштувань';

  @override
  String get optionCodecTitle => 'Формат для монтажу';

  @override
  String get cmdHideBanner => 'Не виводити інформацію про версію';

  @override
  String get cmdSeek => 'Почати з цього місця відео, у секундах';

  @override
  String get cmdInput => 'Відео, яке конвертується';

  @override
  String get cmdLength => 'Конвертувати лише стільки секунд';

  @override
  String get cmdKeepPicture => 'Взяти зображення з оригіналу';

  @override
  String get cmdKeepSound => 'Взяти всі звукові доріжки, якщо вони є';

  @override
  String get cmdNoPicture => 'Без зображення';

  @override
  String get cmdNoSound => 'Без звуку';

  @override
  String get cmdKeepMetadata => 'Зберегти дати, назви і таймкод';

  @override
  String get cmdDropMetadata => 'Прибрати дати, назви та інші відомості';

  @override
  String get cmdPictureCopy => 'Зображення: скопіювати як є, без втрати якості';

  @override
  String get cmdPictureEncoder => 'Зображення: перекодувати цим кодувальником';

  @override
  String get cmdSoundCopy => 'Звук: скопіювати як є';

  @override
  String get cmdSoundEncoder => 'Звук: перетворити в цей формат';

  @override
  String get cmdSpeedPreset =>
      'Старанність: повільніше дає менший файл за тієї ж якості';

  @override
  String get cmdQuality =>
      'Цільова якість (для більшості кодувальників менше число означає кращу якість і більший файл)';

  @override
  String get cmdProfile => 'Різновид формату';

  @override
  String get cmdEncoderTuning => 'Тонке налаштування кодувальника';

  @override
  String get cmdPixelFormat => 'Точність кольору зображення';

  @override
  String get cmdFilter => 'Обробка зображення';

  @override
  String get cmdSoundBitrate => 'Якість звуку, обсяг даних за секунду';

  @override
  String get cmdConstantFrameRate => 'Зробити частоту кадрів рівномірною';

  @override
  String get cmdFrameRate => 'Кадрів за секунду';

  @override
  String get cmdKeyframeInterval =>
      'Повний кадр щонайменше з такою частотою, для плавного перемотування';

  @override
  String get cmdPlayerTag =>
      'Позначка, за якою відео розпізнають програвачі Apple';

  @override
  String get cmdFastStart =>
      'Індекс на початку, щоб відтворення починалося під час завантаження';

  @override
  String get cmdContainer => 'Тип файлу результату';

  @override
  String get cmdOutput => 'Куди записується результат';

  @override
  String get scenarioShareTitle => 'Надіслати на телефон';

  @override
  String get scenarioShareHint =>
      'Маленький файл, що відтворюється на будь-якому телефоні, у Telegram та інших месенджерах. У Telegram надсилайте як файл, щоб зберегти цю якість.';

  @override
  String get scenarioAudioTitle => 'Дістати звук';

  @override
  String get scenarioAudioHint => 'Зберігає звук із відео окремим файлом.';

  @override
  String get scenarioPrivacyTitle => 'Прибрати особисті дані';

  @override
  String get scenarioPrivacyHint =>
      'Прибирає приховані позначки про місце, дату, камеру й автора перед тим, як ділитися відео. Те, що видно і чутно, не змінюється.';

  @override
  String get scenarioRemuxTitle => 'Змінити тип файлу';

  @override
  String get scenarioRemuxHint =>
      'За секунди перекладає відео в інший тип файлу, не змінюючи якості зображення.';

  @override
  String get optionSizeTitle => 'Розмір';

  @override
  String get shareSmall => 'Менший';

  @override
  String get shareStandard => 'Стандартний';

  @override
  String get optionFormatTitle => 'Тип файлу';

  @override
  String get formatOriginal => 'Як є';

  @override
  String get optionModeTitle => 'Наскільки ретельно';

  @override
  String get modeQuick => 'Швидко';

  @override
  String get modeThorough => 'Ретельно';

  @override
  String get modeThoroughHint =>
      'Ретельний режим заново створює зображення і звук. Це значно довше, але найнадійніше.';

  @override
  String get noteHdrToneMapped =>
      'Дуже яскраві кольори буде пристосовано, щоб відео гарно виглядало на будь-якому екрані.';

  @override
  String get noteHdrNotConverted =>
      'У цьому відео надяскраві кольори, які на телефоні можуть виглядати блідо.';

  @override
  String get noteAudioConvertedToFit =>
      'Звук буде перетворено, щоб він підходив до цього типу файлу.';

  @override
  String get statusNoSound => 'У цьому файлі немає звуку';

  @override
  String get statusCannotHold => 'Цей тип файлу не може містити таке відео';
}
