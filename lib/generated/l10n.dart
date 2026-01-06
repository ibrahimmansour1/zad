// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Original Text`
  String get original_text {
    return Intl.message(
      'Original Text',
      name: 'original_text',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `Spanish`
  String get spanish {
    return Intl.message('Spanish', name: 'spanish', desc: '', args: []);
  }

  /// `Chinese`
  String get chinese {
    return Intl.message('Chinese', name: 'chinese', desc: '', args: []);
  }

  /// `Hindi`
  String get hindi {
    return Intl.message('Hindi', name: 'hindi', desc: '', args: []);
  }

  /// `Arabic`
  String get arabic {
    return Intl.message('Arabic', name: 'arabic', desc: '', args: []);
  }

  /// `French`
  String get french {
    return Intl.message('French', name: 'french', desc: '', args: []);
  }

  /// `Bengali`
  String get bengali {
    return Intl.message('Bengali', name: 'bengali', desc: '', args: []);
  }

  /// `Russian`
  String get russian {
    return Intl.message('Russian', name: 'russian', desc: '', args: []);
  }

  /// `Portuguese`
  String get portuguese {
    return Intl.message('Portuguese', name: 'portuguese', desc: '', args: []);
  }

  /// `Urdu`
  String get urdu {
    return Intl.message('Urdu', name: 'urdu', desc: '', args: []);
  }

  /// `German`
  String get german {
    return Intl.message('German', name: 'german', desc: '', args: []);
  }

  /// `Japanese`
  String get japanese {
    return Intl.message('Japanese', name: 'japanese', desc: '', args: []);
  }

  /// `Punjabi`
  String get punjabi {
    return Intl.message('Punjabi', name: 'punjabi', desc: '', args: []);
  }

  /// `Telugu`
  String get telugu {
    return Intl.message('Telugu', name: 'telugu', desc: '', args: []);
  }

  /// `Dismiss`
  String get dismiss {
    return Intl.message('Dismiss', name: 'dismiss', desc: '', args: []);
  }

  /// `Note`
  String get note {
    return Intl.message('Note', name: 'note', desc: '', args: []);
  }

  /// `Image is downloaded successfully`
  String get imageDownloaded {
    return Intl.message(
      'Image is downloaded successfully',
      name: 'imageDownloaded',
      desc: '',
      args: [],
    );
  }

  /// `Item Id`
  String get itemId {
    return Intl.message('Item Id', name: 'itemId', desc: '', args: []);
  }

  /// `Content copied to clipboard`
  String get contentCopied {
    return Intl.message(
      'Content copied to clipboard',
      name: 'contentCopied',
      desc: '',
      args: [],
    );
  }

  /// `Content Language`
  String get contentLanguage {
    return Intl.message(
      'Content Language',
      name: 'contentLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Intro to Islam`
  String get introToIslam {
    return Intl.message(
      'Intro to Islam',
      name: 'introToIslam',
      desc: '',
      args: [],
    );
  }

  /// `Christians dialog`
  String get christiansDialog {
    return Intl.message(
      'Christians dialog',
      name: 'christiansDialog',
      desc: '',
      args: [],
    );
  }

  /// `Atheist dialog`
  String get atheistDialog {
    return Intl.message(
      'Atheist dialog',
      name: 'atheistDialog',
      desc: '',
      args: [],
    );
  }

  /// `Other sects`
  String get otherSects {
    return Intl.message('Other sects', name: 'otherSects', desc: '', args: []);
  }

  /// `Why Islam Is True?`
  String get whyIslamIsTrue {
    return Intl.message(
      'Why Islam Is True?',
      name: 'whyIslamIsTrue',
      desc: '',
      args: [],
    );
  }

  /// `Teaching new muslims`
  String get teachingNewMuslims {
    return Intl.message(
      'Teaching new muslims',
      name: 'teachingNewMuslims',
      desc: '',
      args: [],
    );
  }

  /// `Questions about islam`
  String get questionsAboutIslam {
    return Intl.message(
      'Questions about islam',
      name: 'questionsAboutIslam',
      desc: '',
      args: [],
    );
  }

  /// `Daia guide`
  String get daiaGuide {
    return Intl.message('Daia guide', name: 'daiaGuide', desc: '', args: []);
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Spanish`
  String get espanol {
    return Intl.message('Spanish', name: 'espanol', desc: '', args: []);
  }

  /// `Portuguese`
  String get portugues {
    return Intl.message('Portuguese', name: 'portugues', desc: '', args: []);
  }

  /// `French`
  String get francais {
    return Intl.message('French', name: 'francais', desc: '', args: []);
  }

  /// `Filipino`
  String get filipino {
    return Intl.message('Filipino', name: 'filipino', desc: '', args: []);
  }

  /// `Search...`
  String get search {
    return Intl.message('Search...', name: 'search', desc: '', args: []);
  }

  /// `No Items`
  String get noItems {
    return Intl.message('No Items', name: 'noItems', desc: '', args: []);
  }

  /// `Add Article Title`
  String get addArticleTitle {
    return Intl.message(
      'Add Article Title',
      name: 'addArticleTitle',
      desc: '',
      args: [],
    );
  }

  /// `Section`
  String get section {
    return Intl.message('Section', name: 'section', desc: '', args: []);
  }

  /// `Category`
  String get category {
    return Intl.message('Category', name: 'category', desc: '', args: []);
  }

  /// `Choose Category From Suggestions`
  String get chooseCategoryFromSuggestions {
    return Intl.message(
      'Choose Category From Suggestions',
      name: 'chooseCategoryFromSuggestions',
      desc: '',
      args: [],
    );
  }

  /// `Article Title`
  String get articleTitle {
    return Intl.message(
      'Article Title',
      name: 'articleTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter Article Title`
  String get enterArticleTitle {
    return Intl.message(
      'Enter Article Title',
      name: 'enterArticleTitle',
      desc: '',
      args: [],
    );
  }

  /// `Adding Article Title Failed`
  String get addingArticleFailed {
    return Intl.message(
      'Adding Article Title Failed',
      name: 'addingArticleFailed',
      desc: '',
      args: [],
    );
  }

  /// `Adding Article Title Was Successful`
  String get addingArticleSuccess {
    return Intl.message(
      'Adding Article Title Was Successful',
      name: 'addingArticleSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Add Category Title`
  String get addCategoryTitle {
    return Intl.message(
      'Add Category Title',
      name: 'addCategoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Category Title`
  String get categoryTitle {
    return Intl.message(
      'Category Title',
      name: 'categoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter Category Title`
  String get enterCategoryTitle {
    return Intl.message(
      'Enter Category Title',
      name: 'enterCategoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Adding Category Failed`
  String get addingCategoryFailed {
    return Intl.message(
      'Adding Category Failed',
      name: 'addingCategoryFailed',
      desc: '',
      args: [],
    );
  }

  /// `Adding Category Was Successful`
  String get addingCategorySuccess {
    return Intl.message(
      'Adding Category Was Successful',
      name: 'addingCategorySuccess',
      desc: '',
      args: [],
    );
  }

  /// `Add Item`
  String get addItem {
    return Intl.message('Add Item', name: 'addItem', desc: '', args: []);
  }

  /// `Article`
  String get article {
    return Intl.message('Article', name: 'article', desc: '', args: []);
  }

  /// `Order`
  String get order {
    return Intl.message('Order', name: 'order', desc: '', args: []);
  }

  /// `Required`
  String get required {
    return Intl.message('Required', name: 'required', desc: '', args: []);
  }

  /// `Text`
  String get text {
    return Intl.message('Text', name: 'text', desc: '', args: []);
  }

  /// `Image`
  String get image {
    return Intl.message('Image', name: 'image', desc: '', args: []);
  }

  /// `Video`
  String get video {
    return Intl.message('Video', name: 'video', desc: '', args: []);
  }

  /// `Video Id`
  String get videoId {
    return Intl.message('Video Id', name: 'videoId', desc: '', args: []);
  }

  /// `Item Note`
  String get itemNote {
    return Intl.message('Item Note', name: 'itemNote', desc: '', args: []);
  }

  /// `Add Image Before Submitting`
  String get addImageBeforeSubmitting {
    return Intl.message(
      'Add Image Before Submitting',
      name: 'addImageBeforeSubmitting',
      desc: '',
      args: [],
    );
  }

  /// `Adding Item Failed`
  String get addingItemFailed {
    return Intl.message(
      'Adding Item Failed',
      name: 'addingItemFailed',
      desc: '',
      args: [],
    );
  }

  /// `Adding Item Was Successful`
  String get addingItemSuccess {
    return Intl.message(
      'Adding Item Was Successful',
      name: 'addingItemSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Admin`
  String get admin {
    return Intl.message('Admin', name: 'admin', desc: '', args: []);
  }

  /// `Edit Item`
  String get editItem {
    return Intl.message('Edit Item', name: 'editItem', desc: '', args: []);
  }

  /// `Choose Article From Suggestions`
  String get chooseArticleFromSuggestions {
    return Intl.message(
      'Choose Article From Suggestions',
      name: 'chooseArticleFromSuggestions',
      desc: '',
      args: [],
    );
  }

  /// `Editing Item Failed`
  String get editingItemFailed {
    return Intl.message(
      'Editing Item Failed',
      name: 'editingItemFailed',
      desc: '',
      args: [],
    );
  }

  /// `Editing Item Was Successful`
  String get editingItemSuccess {
    return Intl.message(
      'Editing Item Was Successful',
      name: 'editingItemSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Deleting Item Failed`
  String get deletingItemFailed {
    return Intl.message(
      'Deleting Item Failed',
      name: 'deletingItemFailed',
      desc: '',
      args: [],
    );
  }

  /// `Deleting Item Was Successful`
  String get deletingItemSuccess {
    return Intl.message(
      'Deleting Item Was Successful',
      name: 'deletingItemSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Delete Item`
  String get deleteItem {
    return Intl.message('Delete Item', name: 'deleteItem', desc: '', args: []);
  }

  /// `Add Image +`
  String get addImage {
    return Intl.message('Add Image +', name: 'addImage', desc: '', args: []);
  }

  /// `Item Title`
  String get itemTitle {
    return Intl.message('Item Title', name: 'itemTitle', desc: '', args: []);
  }

  /// `Item Content`
  String get itemContent {
    return Intl.message(
      'Item Content',
      name: 'itemContent',
      desc: '',
      args: [],
    );
  }

  /// `Enter Password`
  String get enterPassword {
    return Intl.message(
      'Enter Password',
      name: 'enterPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Please enter your password`
  String get pleaseEnterPassword {
    return Intl.message(
      'Please enter your password',
      name: 'pleaseEnterPassword',
      desc: '',
      args: [],
    );
  }

  /// `Wrong Password`
  String get wrongPassword {
    return Intl.message(
      'Wrong Password',
      name: 'wrongPassword',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continu {
    return Intl.message('Continue', name: 'continu', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
