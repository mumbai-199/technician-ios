import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  static final AppLanguage instance = AppLanguage._();
  static const _preferenceKey = 'technician_app_language';
  static const supportedLanguageCodes = ['en', 'hi', 'mr'];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_preferenceKey);
    if (savedCode != null && supportedLanguageCodes.contains(savedCode)) {
      _locale = Locale(savedCode);
    }
    await _applyLocale();
  }

  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode) ||
        _locale.languageCode == languageCode) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, languageCode);
    _locale = Locale(languageCode);
    await _applyLocale();
    notifyListeners();
  }

  Future<void> _applyLocale() async {
    Intl.defaultLocale = _locale.languageCode;
    await initializeDateFormatting(_locale.languageCode);
  }
}

class AppText {
  static const _translations = <String, List<String>>{
    'Language': ['Language', 'भाषा', 'भाषा'],
    'Choose language': ['Choose language', 'भाषा चुनें', 'भाषा निवडा'],
    'Menu': ['Menu', 'मेनू', 'मेनू'],
    'Profile': ['Profile', 'प्रोफ़ाइल', 'प्रोफाइल'],
    'Leave': ['Leave', 'छुट्टी', 'रजा'],
    'Expense': ['Expense', 'खर्च', 'खर्च'],
    'Start Km': ['Start Km', 'शुरुआती किमी', 'सुरुवातीचे किमी'],
    'End Km': ['End Km', 'अंतिम किमी', 'शेवटचे किमी'],
    'Chem In': ['Chem In', 'केमिकल जमा', 'केमिकल जमा'],
    'Chem Out': ['Chem Out', 'केमिकल निकासी', 'केमिकल वापर'],
    'Advance': ['Advance', 'अग्रिम', 'अॅडव्हान्स'],
    'Cash': ['Cash', 'नकद', 'रोख'],
    'Account': ['Account', 'खाता', 'खाते'],
    'Cheque': ['Cheque', 'चेक', 'धनादेश'],
    'Branches': ['Branches', 'शाखाएँ', 'शाखा'],
    'Help': ['Help', 'सहायता', 'मदत'],
    'Logout': ['Logout', 'लॉग आउट', 'लॉग आउट'],
    'Technician': ['Technician', 'तकनीशियन', 'तंत्रज्ञ'],
    'Today overview': ['Today overview', 'आज का सारांश', 'आजचा आढावा'],
    'Jobs, payments, and service flow in one place.': [
      'Jobs, payments, and service flow in one place.',
      'काम, भुगतान और सेवा की जानकारी एक ही जगह।',
      'कामे, पेमेंट आणि सेवा माहिती एकाच ठिकाणी.',
    ],
    'Job History': ['Job History', 'काम का इतिहास', 'कामाचा इतिहास'],
    'Pending': ['Pending', 'बाकी', 'प्रलंबित'],
    'Completed': ['Completed', 'पूर्ण', 'पूर्ण'],
    'Payment History': ['Payment History', 'भुगतान इतिहास', 'पेमेंट इतिहास'],
    'Online': ['Online', 'ऑनलाइन', 'ऑनलाइन'],
    'Cash Pending': ['Cash Pending', 'नकद बाकी', 'रोख बाकी'],
    'My Jobs': ['My Jobs', 'मेरे काम', 'माझी कामे'],
    'Tomorrow': ['Tomorrow', 'कल', 'उद्या'],
    'No jobs assigned yet': [
      'No jobs assigned yet',
      'अभी तक कोई काम असाइन नहीं हुआ',
      'अजून कोणतेही काम दिलेले नाही',
    ],
    'Not scheduled': ['Not scheduled', 'निर्धारित नहीं', 'नियोजित नाही'],
    'Rescheduled': ['Rescheduled', 'पुनर्निर्धारित', 'पुन्हा नियोजित'],
    'In Progress': ['In Progress', 'काम जारी है', 'काम सुरू आहे'],
    'Assigned': ['Assigned', 'असाइन किया गया', 'नेमलेले'],
    'Started': ['Started', 'शुरू हुआ', 'सुरू झाले'],
    'Ready to Start': [
      'Ready to Start',
      'शुरू करने के लिए तैयार',
      'सुरू करण्यासाठी तयार'
    ],
    'COMPLAINT': ['COMPLAINT', 'शिकायत', 'तक्रार'],
    'Name:': ['Name:', 'नाम:', 'नाव:'],
    'Address:': ['Address:', 'पता:', 'पत्ता:'],
    'Service:': ['Service:', 'सेवा:', 'सेवा:'],
    'Treatment:': ['Treatment:', 'उपचार:', 'उपचार:'],
    'Area:': ['Area:', 'क्षेत्र:', 'भाग:'],
    'Call': ['Call', 'कॉल करें', 'कॉल करा'],
    'Call Marketing': [
      'Call Marketing',
      'मार्केटिंग को कॉल करें',
      'मार्केटिंगला कॉल करा'
    ],
    'No customer phone number is available': [
      'No customer phone number is available',
      'ग्राहक का फ़ोन नंबर उपलब्ध नहीं है',
      'ग्राहकाचा फोन नंबर उपलब्ध नाही',
    ],
    'No marketing phone number is available': [
      'No marketing phone number is available',
      'मार्केटिंग का फ़ोन नंबर उपलब्ध नहीं है',
      'मार्केटिंगचा फोन नंबर उपलब्ध नाही',
    ],
    'Unable to open the phone app': [
      'Unable to open the phone app',
      'फ़ोन ऐप नहीं खुल सका',
      'फोन अॅप उघडता आले नाही',
    ],
    'No map location is available': [
      'No map location is available',
      'मानचित्र स्थान उपलब्ध नहीं है',
      'नकाशाचे ठिकाण उपलब्ध नाही',
    ],
    'Unable to open Google Maps': [
      'Unable to open Google Maps',
      'Google Maps नहीं खुल सका',
      'Google Maps उघडता आले नाही',
    ],
    'Map': ['Map', 'मानचित्र', 'नकाशा'],
    'View Details': ['View Details', 'विवरण देखें', 'तपशील पहा'],
    'Start Job': ['Start Job', 'काम शुरू करें', 'काम सुरू करा'],
    'Welcome Back!': [
      'Welcome Back!',
      'वापसी पर स्वागत है!',
      'पुन्हा स्वागत आहे!'
    ],
    'Login to continue': [
      'Login to continue',
      'जारी रखने के लिए लॉगिन करें',
      'पुढे जाण्यासाठी लॉगिन करा'
    ],
    'Email': ['Email', 'ईमेल', 'ईमेल'],
    'Password': ['Password', 'पासवर्ड', 'पासवर्ड'],
    'Remember me': ['Remember me', 'मुझे याद रखें', 'मला लक्षात ठेवा'],
    'Forgot Password?': [
      'Forgot Password?',
      'पासवर्ड भूल गए?',
      'पासवर्ड विसरलात?'
    ],
    'LOGIN': ['LOGIN', 'लॉगिन', 'लॉगिन'],
    'Secure technician access portal': [
      'Secure technician access portal',
      'तकनीशियन का सुरक्षित प्रवेश पोर्टल',
      'तंत्रज्ञांसाठी सुरक्षित प्रवेश पोर्टल'
    ],
    'Please enter Email and Password': [
      'Please enter Email and Password',
      'कृपया ईमेल और पासवर्ड दर्ज करें',
      'कृपया ईमेल आणि पासवर्ड भरा'
    ],
    'Create Account': ['Create Account', 'खाता बनाएँ', 'खाते तयार करा'],
    'Join Our Team': [
      'Join Our Team',
      'हमारी टीम से जुड़ें',
      'आमच्या टीममध्ये सामील व्हा'
    ],
    'Confirm Password': [
      'Confirm Password',
      'पासवर्ड की पुष्टि करें',
      'पासवर्डची पुष्टी करा'
    ],
    'My Profile': ['My Profile', 'मेरी प्रोफ़ाइल', 'माझे प्रोफाइल'],
    'Technician Code': ['Technician Code', 'तकनीशियन कोड', 'तंत्रज्ञ कोड'],
    'User ID': ['User ID', 'यूज़र आईडी', 'वापरकर्ता आयडी'],
    'Phone Number': ['Phone Number', 'फ़ोन नंबर', 'फोन नंबर'],
    'City': ['City', 'शहर', 'शहर'],
    'State': ['State', 'राज्य', 'राज्य'],
    'Address': ['Address', 'पता', 'पत्ता'],
    'Reference': ['Reference', 'संदर्भ', 'संदर्भ'],
    'Update Profile': [
      'Update Profile',
      'प्रोफ़ाइल अपडेट करें',
      'प्रोफाइल अपडेट करा'
    ],
    'Profile picture updated successfully!': [
      'Profile picture updated successfully!',
      'प्रोफ़ाइल फ़ोटो सफलतापूर्वक अपडेट हुई!',
      'प्रोफाइल फोटो यशस्वीरित्या अपडेट झाला!'
    ],
    'Expense List': ['Expense List', 'खर्च सूची', 'खर्च यादी'],
    'Please fill all fields': [
      'Please fill all fields',
      'कृपया सभी फ़ील्ड भरें',
      'कृपया सर्व माहिती भरा'
    ],
    'Advance Apply': [
      'Advance Apply',
      'अग्रिम के लिए आवेदन',
      'अॅडव्हान्ससाठी अर्ज'
    ],
    'Amount (₹)': ['Amount (₹)', 'राशि (₹)', 'रक्कम (₹)'],
    'Reason for advance...': [
      'Reason for advance...',
      'अग्रिम का कारण...',
      'अॅडव्हान्सचे कारण...'
    ],
    'Leave Apply': ['Leave Apply', 'छुट्टी के लिए आवेदन', 'रजेसाठी अर्ज'],
    'Sick Leave': ['Sick Leave', 'बीमारी की छुट्टी', 'आजारपणाची रजा'],
    'Casual Leave': ['Casual Leave', 'आकस्मिक छुट्टी', 'किरकोळ रजा'],
    'Emergency Leave': ['Emergency Leave', 'आपातकालीन छुट्टी', 'आपत्कालीन रजा'],
    'Other': ['Other', 'अन्य', 'इतर'],
    'Enter reason for leave...': [
      'Enter reason for leave...',
      'छुट्टी का कारण दर्ज करें...',
      'रजेचे कारण लिहा...'
    ],
    'Location:': ['Location:', 'स्थान:', 'ठिकाण:'],
    'Kilometer Reading': [
      'Kilometer Reading',
      'किलोमीटर रीडिंग',
      'किलोमीटर रीडिंग'
    ],
    'Take Photo': ['Take Photo', 'फ़ोटो लें', 'फोटो काढा'],
    'Retake': ['Retake', 'फिर से लें', 'पुन्हा घ्या'],
    'Remove': ['Remove', 'हटाएँ', 'काढून टाका'],
    'Camera permission is required to take photos': [
      'Camera permission is required to take photos',
      'फ़ोटो लेने के लिए कैमरा अनुमति आवश्यक है',
      'फोटो काढण्यासाठी कॅमेरा परवानगी आवश्यक आहे'
    ],
    'Photo captured successfully!': [
      'Photo captured successfully!',
      'फ़ोटो सफलतापूर्वक ली गई!',
      'फोटो यशस्वीरित्या काढला!'
    ],
    'Chemical In': ['Chemical In', 'केमिकल जमा', 'केमिकल जमा'],
    'Chemical Out': ['Chemical Out', 'केमिकल निकासी', 'केमिकल वापर'],
    'Quantity': ['Quantity', 'मात्रा', 'प्रमाण'],
    'Please enter quantity': [
      'Please enter quantity',
      'कृपया मात्रा दर्ज करें',
      'कृपया प्रमाण भरा'
    ],
    'Cash Submission': ['Cash Submission', 'नकद जमा', 'रोख जमा'],
    'Please select at least one job': [
      'Please select at least one job',
      'कृपया कम से कम एक काम चुनें',
      'कृपया किमान एक काम निवडा'
    ],
    'Please select a cash collector': [
      'Please select a cash collector',
      'कृपया नकद संग्रहकर्ता चुनें',
      'कृपया रोख जमा करणारा निवडा'
    ],
    'Select Image Source': [
      'Select Image Source',
      'चित्र का स्रोत चुनें',
      'प्रतिमेचा स्रोत निवडा'
    ],
    'Camera': ['Camera', 'कैमरा', 'कॅमेरा'],
    'Gallery': ['Gallery', 'गैलरी', 'गॅलरी'],
    'Payment Proof': ['Payment Proof', 'भुगतान का प्रमाण', 'पेमेंटचा पुरावा'],
    'Payment': ['Payment', 'भुगतान', 'पेमेंट'],
    'Amount cannot be negative': [
      'Amount cannot be negative',
      'राशि ऋणात्मक नहीं हो सकती',
      'रक्कम ऋणात्मक असू शकत नाही'
    ],
    'Payment proof is required for this payment type': [
      'Payment proof is required for this payment type',
      'इस भुगतान प्रकार के लिए भुगतान प्रमाण आवश्यक है',
      'या पेमेंट प्रकारासाठी पेमेंटचा पुरावा आवश्यक आहे'
    ],
    'Payment proof captured successfully!': [
      'Payment proof captured successfully!',
      'भुगतान का प्रमाण सफलतापूर्वक लिया गया!',
      'पेमेंटचा पुरावा यशस्वीरित्या घेतला!'
    ],
    'Payment proof removed': [
      'Payment proof removed',
      'भुगतान का प्रमाण हटाया गया',
      'पेमेंटचा पुरावा काढून टाकला'
    ],
    'Payment saved & job completed!': [
      'Payment saved & job completed!',
      'भुगतान सहेजा गया और काम पूरा हुआ!',
      'पेमेंट जतन झाले आणि काम पूर्ण झाले!'
    ],
    'Pay Full': ['Pay Full', 'पूरा भुगतान करें', 'पूर्ण पेमेंट करा'],
    'Job Completed!': ['Job Completed!', 'काम पूरा हुआ!', 'काम पूर्ण झाले!'],
    'Download PDF': ['Download PDF', 'PDF डाउनलोड करें', 'PDF डाउनलोड करा'],
    'Share on WhatsApp': [
      'Share on WhatsApp',
      'WhatsApp पर साझा करें',
      'WhatsApp वर शेअर करा'
    ],
    'Skip': ['Skip', 'छोड़ें', 'वगळा'],
    'Job started successfully!': [
      'Job started successfully!',
      'काम सफलतापूर्वक शुरू हुआ!',
      'काम यशस्वीरित्या सुरू झाले!'
    ],
    'Close Job': ['Close Job', 'काम बंद करें', 'काम बंद करा'],
    'Cancel': ['Cancel', 'रद्द करें', 'रद्द करा'],
    'Job closed successfully!': [
      'Job closed successfully!',
      'काम सफलतापूर्वक बंद हुआ!',
      'काम यशस्वीरित्या बंद झाले!'
    ],
    'Job grabbed successfully!': [
      'Job grabbed successfully!',
      'काम सफलतापूर्वक लिया गया!',
      'काम यशस्वीरित्या घेतले!'
    ],
    'Phone number not available': [
      'Phone number not available',
      'फ़ोन नंबर उपलब्ध नहीं है',
      'फोन नंबर उपलब्ध नाही'
    ],
    'Could not open phone dialer': [
      'Could not open phone dialer',
      'फ़ोन डायलर नहीं खुल सका',
      'फोन डायलर उघडता आला नाही'
    ],
    'Before photos uploaded successfully!': [
      'Before photos uploaded successfully!',
      'पहले की फ़ोटो सफलतापूर्वक अपलोड हुईं!',
      'आधीचे फोटो यशस्वीरित्या अपलोड झाले!'
    ],
    'After photos uploaded successfully!': [
      'After photos uploaded successfully!',
      'बाद की फ़ोटो सफलतापूर्वक अपलोड हुईं!',
      'नंतरचे फोटो यशस्वीरित्या अपलोड झाले!'
    ],
    'Photos uploaded successfully!': [
      'Photos uploaded successfully!',
      'फ़ोटो सफलतापूर्वक अपलोड हुईं!',
      'फोटो यशस्वीरित्या अपलोड झाले!'
    ],
    'Please add at least one before photo': [
      'Please add at least one before photo',
      'कृपया पहले की कम से कम एक फ़ोटो जोड़ें',
      'कृपया आधीचा किमान एक फोटो जोडा'
    ],
    'Please add at least one after photo': [
      'Please add at least one after photo',
      'कृपया बाद की कम से कम एक फ़ोटो जोड़ें',
      'कृपया नंतरचा किमान एक फोटो जोडा'
    ],
    'Please add at least one photo': [
      'Please add at least one photo',
      'कृपया कम से कम एक फ़ोटो जोड़ें',
      'कृपया किमान एक फोटो जोडा'
    ],
    'Camera and storage permissions are required': [
      'Camera and storage permissions are required',
      'कैमरा और स्टोरेज की अनुमति आवश्यक है',
      'कॅमेरा आणि स्टोरेज परवानग्या आवश्यक आहेत'
    ],
    'Please provide signature first': [
      'Please provide signature first',
      'कृपया पहले हस्ताक्षर करें',
      'कृपया आधी स्वाक्षरी करा'
    ],
    'Signature uploaded successfully!': [
      'Signature uploaded successfully!',
      'हस्ताक्षर सफलतापूर्वक अपलोड हुए!',
      'स्वाक्षरी यशस्वीरित्या अपलोड झाली!'
    ],
    'Help & Support': ['Help & Support', 'सहायता और समर्थन', 'मदत आणि समर्थन'],
    'Retry': ['Retry', 'फिर से कोशिश करें', 'पुन्हा प्रयत्न करा'],
    'Phone': ['Phone', 'फ़ोन', 'फोन'],
    'Direction': ['Direction', 'दिशा', 'दिशा'],
    'Admin Note': ['Admin Note', 'एडमिन नोट', 'अॅडमिन नोट'],
    'Grab': ['Grab', 'काम लें', 'काम घ्या'],
    'Start': ['Start', 'शुरू करें', 'सुरू करा'],
    'Paid Type: Cash': [
      'Paid Type: Cash',
      'भुगतान प्रकार: नकद',
      'पेमेंट प्रकार: रोख'
    ],
    'Amount:': ['Amount:', 'राशि:', 'रक्कम:'],
    'My Referrals': ['My Referrals', 'मेरे रेफ़रल', 'माझे रेफरल'],
    'Your Referral Code': [
      'Your Referral Code',
      'आपका रेफ़रल कोड',
      'तुमचा रेफरल कोड'
    ],
    'SHARE CODE': ['SHARE CODE', 'कोड साझा करें', 'कोड शेअर करा'],
    'No recent activity': [
      'No recent activity',
      'हाल की कोई गतिविधि नहीं',
      'अलीकडील गतिविधी नाही'
    ],
    'No recent notifications': [
      'No recent notifications',
      'हाल की कोई सूचना नहीं',
      'अलीकडील सूचना नाही'
    ],
    'Start chat': ['Start chat', 'चैट शुरू करें', 'चॅट सुरू करा'],
    'Choose an admin or marketing user': [
      'Choose an admin or marketing user',
      'एडमिन या मार्केटिंग उपयोगकर्ता चुनें',
      'अॅडमिन किंवा मार्केटिंग वापरकर्ता निवडा'
    ],
    'No admins or marketing users available.': [
      'No admins or marketing users available.',
      'कोई एडमिन या मार्केटिंग उपयोगकर्ता उपलब्ध नहीं है।',
      'अॅडमिन किंवा मार्केटिंग वापरकर्ता उपलब्ध नाही.'
    ],
    'Contact': ['Contact', 'संपर्क', 'संपर्क'],
    'CONVERSATIONS': ['CONVERSATIONS', 'बातचीत', 'संभाषणे'],
    'UNREAD': ['UNREAD', 'अपठित', 'न वाचलेले'],
    'Attendance': ['Attendance', 'उपस्थिति', 'उपस्थिती'],
    'Shift Attendance': [
      'Shift Attendance',
      'शिफ्ट उपस्थिति',
      'शिफ्ट उपस्थिती'
    ],
    'Today': ['Today', 'आज', 'आज'],
    'Yesterday': ['Yesterday', 'कल', 'काल'],
    'Present': ['Present', 'उपस्थित', 'उपस्थित'],
    'Absent': ['Absent', 'अनुपस्थित', 'अनुपस्थित'],
    'On Leave': ['On Leave', 'छुट्टी पर', 'रजेवर'],
    'Fetching location...': [
      'Fetching location...',
      'स्थान प्राप्त हो रहा है...',
      'ठिकाण मिळवत आहे...'
    ],
    'Location service disabled': [
      'Location service disabled',
      'स्थान सेवा बंद है',
      'स्थान सेवा बंद आहे'
    ],
    'Location permission denied': [
      'Location permission denied',
      'स्थान की अनुमति अस्वीकृत है',
      'स्थान परवानगी नाकारली आहे'
    ],
    'Tomorrow Jobs': ['Tomorrow Jobs', 'कल के काम', 'उद्याची कामे'],
    'No jobs scheduled for tomorrow': [
      'No jobs scheduled for tomorrow',
      'कल के लिए कोई काम निर्धारित नहीं है',
      'उद्यासाठी कोणतीही कामे नियोजित नाहीत'
    ],
    'Today Jobs': ['Today Jobs', 'आज के काम', 'आजची कामे'],
    'Before Photos': ['Before Photos', 'पहले की फ़ोटो', 'आधीचे फोटो'],
    'After Photos': ['After Photos', 'बाद की फ़ोटो', 'नंतरचे फोटो'],
    'Customer Signature': [
      'Customer Signature',
      'ग्राहक के हस्ताक्षर',
      'ग्राहकाची स्वाक्षरी'
    ],
    'Add-on services': ['Add-on services', 'अतिरिक्त सेवाएँ', 'अतिरिक्त सेवा'],
    'Please add at least one service': [
      'Please add at least one service',
      'कृपया कम से कम एक सेवा जोड़ें',
      'कृपया किमान एक सेवा जोडा'
    ],
    'Please enter service name for all services': [
      'Please enter service name for all services',
      'कृपया सभी सेवाओं के नाम दर्ज करें',
      'कृपया सर्व सेवांची नावे भरा'
    ],
    'Please enter valid amount for all services': [
      'Please enter valid amount for all services',
      'कृपया सभी सेवाओं के लिए सही राशि दर्ज करें',
      'कृपया सर्व सेवांसाठी योग्य रक्कम भरा'
    ],
    'Add-on services added successfully!': [
      'Add-on services added successfully!',
      'अतिरिक्त सेवाएँ सफलतापूर्वक जोड़ी गईं!',
      'अतिरिक्त सेवा यशस्वीरित्या जोडल्या!'
    ],
    'Bag In': ['Bag In', 'बैग जमा', 'बॅग जमा'],
    'Bag Out': ['Bag Out', 'बैग निकासी', 'बॅग बाहेर'],
    'Debug Information': ['Debug Information', 'डिबग जानकारी', 'डिबग माहिती'],
    'Debug Info': ['Debug Info', 'डिबग जानकारी', 'डिबग माहिती'],
    'Copied to clipboard': [
      'Copied to clipboard',
      'क्लिपबोर्ड पर कॉपी किया गया',
      'क्लिपबोर्डवर कॉपी केले'
    ],
    'Select language': ['Select language', 'भाषा चुनें', 'भाषा निवडा'],
    'Select date': ['Select date', 'तारीख चुनें', 'तारीख निवडा'],
    'Submit': ['Submit', 'जमा करें', 'सबमिट करा'],
    'Save': ['Save', 'सहेजें', 'जतन करा'],
    'Update': ['Update', 'अपडेट करें', 'अपडेट करा'],
    'Search': ['Search', 'खोजें', 'शोधा'],
    'Loading...': ['Loading...', 'लोड हो रहा है...', 'लोड होत आहे...'],
    'Refresh': ['Refresh', 'रीफ़्रेश करें', 'रिफ्रेश करा'],
    'Error': ['Error', 'त्रुटि', 'त्रुटी'],
    'Success': ['Success', 'सफलता', 'यशस्वी'],
    'No data available': [
      'No data available',
      'कोई डेटा उपलब्ध नहीं है',
      'माहिती उपलब्ध नाही'
    ],
    'Error:': ['Error:', 'त्रुटि:', 'त्रुटी:'],
    "Tomorrow's Jobs": [
      "Tomorrow's Jobs",
      'कल के काम',
      'उद्याची कामे',
    ],
    'Total Expense': ['Total Expense', 'कुल खर्च', 'एकूण खर्च'],
    'Advance Summary': [
      'Advance Summary',
      'अग्रिम सारांश',
      'अॅडव्हान्स सारांश'
    ],
    'Total Taken': ['Total Taken', 'कुल लिया गया', 'एकूण घेतले'],
    'Request Advance': [
      'Request Advance',
      'अग्रिम का अनुरोध',
      'अॅडव्हान्सची विनंती'
    ],
    'SUBMIT REQUEST': ['SUBMIT REQUEST', 'अनुरोध जमा करें', 'विनंती सबमिट करा'],
    'Advance History': [
      'Advance History',
      'अग्रिम इतिहास',
      'अॅडव्हान्स इतिहास'
    ],
    'No advance requests yet': [
      'No advance requests yet',
      'अभी तक कोई अग्रिम अनुरोध नहीं',
      'अॅडव्हान्सची विनंती अद्याप नाही'
    ],
    'Admin Notes:': ['Admin Notes:', 'एडमिन नोट्स:', 'अॅडमिन नोट्स:'],
    'User not logged in': [
      'User not logged in',
      'उपयोगकर्ता लॉगिन नहीं है',
      'वापरकर्ता लॉगिन केलेला नाही'
    ],
    'Leave Balance': ['Leave Balance', 'छुट्टी शेष', 'रजा शिल्लक'],
    'No Limit': ['No Limit', 'कोई सीमा नहीं', 'मर्यादा नाही'],
    'Used': ['Used', 'उपयोग किया', 'वापरले'],
    'Apply for Leave': [
      'Apply for Leave',
      'छुट्टी के लिए आवेदन करें',
      'रजेसाठी अर्ज करा'
    ],
    'Leave Type': ['Leave Type', 'छुट्टी का प्रकार', 'रजेचा प्रकार'],
    'From Date': ['From Date', 'शुरू होने की तारीख', 'सुरुवातीची तारीख'],
    'To Date': ['To Date', 'समाप्ति की तारीख', 'शेवटची तारीख'],
    'Select Date': ['Select Date', 'तारीख चुनें', 'तारीख निवडा'],
    'Reason': ['Reason', 'कारण', 'कारण'],
    'SUBMIT LEAVE REQUEST': [
      'SUBMIT LEAVE REQUEST',
      'छुट्टी का अनुरोध जमा करें',
      'रजेची विनंती सबमिट करा'
    ],
    'Add Expense': ['Add Expense', 'खर्च जोड़ें', 'खर्च जोडा'],
    'Category': ['Category', 'श्रेणी', 'वर्ग'],
    'Description': ['Description', 'विवरण', 'तपशील'],
    'ADD EXPENSE': ['ADD EXPENSE', 'खर्च जोड़ें', 'खर्च जोडा'],
    'Receipt Image': ['Receipt Image', 'रसीद की फ़ोटो', 'पावतीचा फोटो'],
    'Choose receipt image': [
      'Choose receipt image',
      'रसीद की फ़ोटो चुनें',
      'पावतीचा फोटो निवडा'
    ],
    'Change receipt image': [
      'Change receipt image',
      'रसीद की फ़ोटो बदलें',
      'पावतीचा फोटो बदला'
    ],
    'Enjoy your free day!': [
      'Enjoy your free day!',
      'अपने खाली दिन का आनंद लें!',
      'तुमच्या मोकळ्या दिवसाचा आनंद घ्या!'
    ],
    'This is a preview of tomorrow\'s jobs. You cannot grab or start these jobs until tomorrow.':
        [
      'This is a preview of tomorrow\'s jobs. You cannot grab or start these jobs until tomorrow.',
      'यह कल के कामों का पूर्वावलोकन है। आप इन कामों को कल से पहले नहीं ले सकते या शुरू नहीं कर सकते।',
      'हा उद्याच्या कामांचा पूर्वावलोकन आहे. उद्यापूर्वी ही कामे घेता किंवा सुरू करता येणार नाहीत.',
    ],
    'Emergency Support': [
      'Emergency Support',
      'आपातकालीन सहायता',
      'आपत्कालीन मदत'
    ],
    '24/7 Available': ['24/7 Available', '24/7 उपलब्ध', '24/7 उपलब्ध'],
    'CALL SUPPORT': [
      'CALL SUPPORT',
      'सहायता के लिए कॉल करें',
      'मदतीसाठी कॉल करा'
    ],
    'Quick Actions': ['Quick Actions', 'त्वरित कार्रवाइयाँ', 'जलद कृती'],
    'Report an Issue': [
      'Report an Issue',
      'समस्या की रिपोर्ट करें',
      'समस्येची नोंद करा'
    ],
    'Technical Support': ['Technical Support', 'तकनीकी सहायता', 'तांत्रिक मदत'],
    'App Feedback': ['App Feedback', 'ऐप पर प्रतिक्रिया', 'अॅपबद्दल अभिप्राय'],
    'Training Videos': [
      'Training Videos',
      'प्रशिक्षण वीडियो',
      'प्रशिक्षण व्हिडिओ'
    ],
    'Frequently Asked Questions': [
      'Frequently Asked Questions',
      'अक्सर पूछे जाने वाले प्रश्न',
      'वारंवार विचारले जाणारे प्रश्न'
    ],
    'How to mark attendance?': [
      'How to mark attendance?',
      'उपस्थिति कैसे दर्ज करें?',
      'उपस्थिती कशी नोंदवायची?'
    ],
    'Go to My Attendance and tap Mark Attendance button.': [
      'Go to My Attendance and tap Mark Attendance button.',
      'मेरी उपस्थिति पर जाएँ और उपस्थिति दर्ज करें बटन दबाएँ।',
      'माझी उपस्थिती येथे जाऊन उपस्थिती नोंदवा बटण दाबा.'
    ],
    'How to apply for leave?': [
      'How to apply for leave?',
      'छुट्टी के लिए आवेदन कैसे करें?',
      'रजेसाठी अर्ज कसा करायचा?'
    ],
    'Navigate to Leave Apply, fill the form and submit.': [
      'Navigate to Leave Apply, fill the form and submit.',
      'छुट्टी आवेदन पर जाएँ, फ़ॉर्म भरें और जमा करें।',
      'रजेच्या अर्जावर जा, फॉर्म भरा आणि सबमिट करा.'
    ],
    'How to track expenses?': [
      'How to track expenses?',
      'खर्च कैसे ट्रैक करें?',
      'खर्चाचा मागोवा कसा घ्यायचा?'
    ],
    'Use Today Expense to add and track your daily expenses.': [
      'Use Today Expense to add and track your daily expenses.',
      'आज का खर्च चुनकर अपने दैनिक खर्च जोड़ें और ट्रैक करें।',
      'आजचा खर्च वापरून दैनंदिन खर्च जोडा आणि त्याचा मागोवा घ्या.'
    ],
    'Enter Starting KM': [
      'Enter Starting KM',
      'शुरुआती किलोमीटर दर्ज करें',
      'सुरुवातीचे किलोमीटर भरा'
    ],
    'Enter Ending KM': [
      'Enter Ending KM',
      'अंतिम किलोमीटर दर्ज करें',
      'शेवटचे किलोमीटर भरा'
    ],
    'Service Name': ['Service Name', 'सेवा का नाम', 'सेवेचे नाव'],
    'Amount (Rs)': ['Amount (Rs)', 'राशि (रु.)', 'रक्कम (रु.)'],
    'e.g., Extra Room Treatment': [
      'e.g., Extra Room Treatment',
      'जैसे, अतिरिक्त कमरे का उपचार',
      'उदा. अतिरिक्त खोलीची सेवा'
    ],
    'Add any notes about this submission...': [
      'Add any notes about this submission...',
      'इस जमा राशि के बारे में कोई टिप्पणी जोड़ें...',
      'या जमा रकमेबद्दल काही नोंदी जोडा...'
    ],
    'Write an update...': [
      'Write an update...',
      'अपडेट लिखें...',
      'अपडेट लिहा...'
    ],
    'Employee ID': ['Employee ID', 'कर्मचारी आईडी', 'कर्मचारी आयडी'],
    'Select payment destination': [
      'Select payment destination',
      'भुगतान गंतव्य चुनें',
      'पेमेंटचे गंतव्य निवडा'
    ],
    'Enter bank/account details': [
      'Enter bank/account details',
      'बैंक/खाते का विवरण दर्ज करें',
      'बँक/खात्याचे तपशील भरा'
    ],
    'Select the account where the customer made the payment.': [
      'Select the account where the customer made the payment.',
      'वह खाता चुनें जिसमें ग्राहक ने भुगतान किया।',
      'ग्राहकाने ज्या खात्यात पेमेंट केले ते खाते निवडा.'
    ],
    'Enter the bank or account details used for this payment.': [
      'Enter the bank or account details used for this payment.',
      'इस भुगतान के लिए उपयोग किए गए बैंक या खाते का विवरण दर्ज करें।',
      'या पेमेंटसाठी वापरलेल्या बँक किंवा खात्याचे तपशील भरा.'
    ],
    'ENTER AMOUNT TO COLLECT': [
      'ENTER AMOUNT TO COLLECT',
      'वसूल की जाने वाली राशि दर्ज करें',
      'वसूल करायची रक्कम भरा'
    ],
    'Enter amount': ['Enter amount', 'राशि दर्ज करें', 'रक्कम भरा'],
    'Enter amount (no job amount set)': [
      'Enter amount (no job amount set)',
      'राशि दर्ज करें (काम की राशि तय नहीं है)',
      'रक्कम भरा (कामाची रक्कम ठरलेली नाही)'
    ],
    'Enter the amount customer is paying': [
      'Enter the amount customer is paying',
      'ग्राहक द्वारा दी जाने वाली राशि दर्ज करें',
      'ग्राहक देत असलेली रक्कम भरा'
    ],
    'NOTES (Optional)': [
      'NOTES (Optional)',
      'टिप्पणियाँ (वैकल्पिक)',
      'नोंदी (ऐच्छिक)'
    ],
    'NOTES FOR NEXT TECHNICIAN': [
      'NOTES FOR NEXT TECHNICIAN',
      'अगले तकनीशियन के लिए टिप्पणियाँ',
      'पुढील तंत्रज्ञासाठी नोंदी'
    ],
    'Add notes that will be visible to the next technician on future visits': [
      'Add notes that will be visible to the next technician on future visits',
      'ऐसी टिप्पणी जोड़ें जो अगली विज़िट पर अगले तकनीशियन को दिखेगी',
      'पुढील भेटीत पुढील तंत्रज्ञाला दिसतील अशा नोंदी जोडा'
    ],
    'Enter notes for next technician (optional)...': [
      'Enter notes for next technician (optional)...',
      'अगले तकनीशियन के लिए टिप्पणी लिखें (वैकल्पिक)...',
      'पुढील तंत्रज्ञासाठी नोंदी लिहा (ऐच्छिक)...'
    ],
    'Reason (Optional)': [
      'Reason (Optional)',
      'कारण (वैकल्पिक)',
      'कारण (ऐच्छिक)'
    ],
    'Reason for Reschedule (Optional)': [
      'Reason for Reschedule (Optional)',
      'पुनर्निर्धारण का कारण (वैकल्पिक)',
      'पुन्हा नियोजनाचे कारण (ऐच्छिक)'
    ],
    'e.g., Customer requested additional treatment': [
      'e.g., Customer requested additional treatment',
      'जैसे, ग्राहक ने अतिरिक्त उपचार का अनुरोध किया',
      'उदा. ग्राहकाने अतिरिक्त उपचाराची विनंती केली'
    ],
    'e.g., Customer requested different date': [
      'e.g., Customer requested different date',
      'जैसे, ग्राहक ने दूसरी तारीख का अनुरोध किया',
      'उदा. ग्राहकाने वेगळी तारीख मागितली'
    ],
    'Branch Details': ['Branch Details', 'शाखा विवरण', 'शाखेचे तपशील'],
    'Branch Details:': ['Branch Details:', 'शाखा विवरण:', 'शाखेचे तपशील:'],
    'Contact Information': [
      'Contact Information',
      'संपर्क जानकारी',
      'संपर्क माहिती'
    ],
    'Location': ['Location', 'स्थान', 'ठिकाण'],
    'Code:': ['Code:', 'कोड:', 'कोड:'],
    'Active': ['Active', 'सक्रिय', 'सक्रिय'],
    'Inactive': ['Inactive', 'निष्क्रिय', 'निष्क्रिय'],
    'No branches found': [
      'No branches found',
      'कोई शाखा नहीं मिली',
      'शाखा आढळल्या नाहीत'
    ],
    'Failed to load branches': [
      'Failed to load branches',
      'शाखाएँ लोड नहीं हो सकीं',
      'शाखा लोड करता आल्या नाहीत'
    ],
    'Failed to load branch details': [
      'Failed to load branch details',
      'शाखा विवरण लोड नहीं हो सका',
      'शाखेचे तपशील लोड करता आले नाहीत'
    ],
    'Could not launch phone dialer': [
      'Could not launch phone dialer',
      'फ़ोन डायलर नहीं खुल सका',
      'फोन डायलर उघडता आला नाही'
    ],
    'Could not launch email app': [
      'Could not launch email app',
      'ईमेल ऐप नहीं खुल सका',
      'ईमेल अॅप उघडता आले नाही'
    ],
    'Notifications': ['Notifications', 'सूचनाएँ', 'सूचना'],
    'Your technician activity will appear here once you have new updates.': [
      'Your technician activity will appear here once you have new updates.',
      'नए अपडेट आने पर आपकी तकनीशियन गतिविधि यहाँ दिखाई देगी।',
      'नवीन अपडेट आल्यावर तुमची तंत्रज्ञ गतिविधी येथे दिसेल.'
    ],
    'Just now': ['Just now', 'अभी-अभी', 'आत्ताच'],
    'My Attendance': ['My Attendance', 'मेरी उपस्थिति', 'माझी उपस्थिती'],
    'Monthly Summary': ['Monthly Summary', 'मासिक सारांश', 'मासिक आढावा'],
    'Total Days': ['Total Days', 'कुल दिन', 'एकूण दिवस'],
    'Total Hours': ['Total Hours', 'कुल घंटे', 'एकूण तास'],
    'Half Day': ['Half Day', 'आधा दिन', 'अर्धा दिवस'],
    'No Data': ['No Data', 'कोई डेटा नहीं', 'माहिती नाही'],
    'No Attendance Records': [
      'No Attendance Records',
      'उपस्थिति रिकॉर्ड नहीं हैं',
      'उपस्थितीची नोंद नाही'
    ],
    'ATTENDANCE DETAILS': [
      'ATTENDANCE DETAILS',
      'उपस्थिति विवरण',
      'उपस्थितीचे तपशील'
    ],
    'End': ['End', 'समाप्त', 'समाप्त'],
    'Today\'s Shift': ['Today\'s Shift', 'आज की शिफ्ट', 'आजची शिफ्ट'],
    'Shift completed': [
      'Shift completed',
      'शिफ्ट पूरी हुई',
      'शिफ्ट पूर्ण झाली'
    ],
    'Track your working hours': [
      'Track your working hours',
      'अपने काम के घंटों को ट्रैक करें',
      'तुमच्या कामाच्या तासांचा मागोवा घ्या'
    ],
    'Not Started': ['Not Started', 'शुरू नहीं हुई', 'सुरू झालेली नाही'],
    'Shift Completed': [
      'Shift Completed',
      'शिफ्ट पूरी हुई',
      'शिफ्ट पूर्ण झाली'
    ],
    'START SHIFT': ['START SHIFT', 'शिफ्ट शुरू करें', 'शिफ्ट सुरू करा'],
    'END SHIFT': ['END SHIFT', 'शिफ्ट समाप्त करें', 'शिफ्ट संपवा'],
    'Submit Cash': ['Submit Cash', 'नकद जमा करें', 'रोख जमा करा'],
    'Total Pending:': ['Total Pending:', 'कुल बाकी:', 'एकूण बाकी:'],
    'Selected Amount:': [
      'Selected Amount:',
      'चुनी गई राशि:',
      'निवडलेली रक्कम:'
    ],
    'SUBMIT CASH TO': [
      'SUBMIT CASH TO',
      'यहाँ नकद जमा करें',
      'येथे रोख जमा करा'
    ],
    'No cash collectors available in your branch': [
      'No cash collectors available in your branch',
      'आपकी शाखा में कोई नकद संग्रहकर्ता उपलब्ध नहीं है',
      'तुमच्या शाखेत रोख जमा करणारा उपलब्ध नाही'
    ],
    'Select Cash Collector': [
      'Select Cash Collector',
      'नकद संग्रहकर्ता चुनें',
      'रोख जमा करणारा निवडा'
    ],
    'Cash will be collected by:': [
      'Cash will be collected by:',
      'नकद जमा करेंगे:',
      'रोख जमा करतील:'
    ],
    'Please select a chemical': [
      'Please select a chemical',
      'कृपया केमिकल चुनें',
      'कृपया केमिकल निवडा'
    ],
    'Receive Chemicals': [
      'Receive Chemicals',
      'केमिकल प्राप्त करें',
      'केमिकल जमा करा'
    ],
    'Issue Chemicals': ['Issue Chemicals', 'केमिकल जारी करें', 'केमिकल वापरा'],
    'Chemical Details': ['Chemical Details', 'केमिकल विवरण', 'केमिकलचे तपशील'],
    'No chemicals available. Please contact admin.': [
      'No chemicals available. Please contact admin.',
      'कोई केमिकल उपलब्ध नहीं है। कृपया एडमिन से संपर्क करें।',
      'केमिकल उपलब्ध नाही. कृपया अॅडमिनशी संपर्क साधा.'
    ],
    'RECEIVE CHEMICAL': [
      'RECEIVE CHEMICAL',
      'केमिकल प्राप्त करें',
      'केमिकल जमा करा'
    ],
    'ISSUE CHEMICAL': ['ISSUE CHEMICAL', 'केमिकल जारी करें', 'केमिकल वापरा'],
    'Current Inventory': [
      'Current Inventory',
      'वर्तमान इन्वेंटरी',
      'सध्याचा साठा'
    ],
    'No inventory available': [
      'No inventory available',
      'इन्वेंटरी उपलब्ध नहीं है',
      'साठा उपलब्ध नाही'
    ],
    'Available Stock': ['Available Stock', 'उपलब्ध स्टॉक', 'उपलब्ध साठा'],
    'Chemical received successfully!': [
      'Chemical received successfully!',
      'केमिकल सफलतापूर्वक प्राप्त हुआ!',
      'केमिकल यशस्वीरित्या जमा झाले!'
    ],
    'Chemical issued successfully!': [
      'Chemical issued successfully!',
      'केमिकल सफलतापूर्वक जारी हुआ!',
      'केमिकल यशस्वीरित्या वापरले!'
    ],
    'Total': ['Total', 'कुल', 'एकूण'],
    'Earnings': ['Earnings', 'कमाई', 'कमाई'],
    'Started at': ['Started at', 'शुरू होने का समय', 'सुरू होण्याची वेळ'],
    'In:': ['In:', 'प्रवेश:', 'सुरू:'],
    'Out:': ['Out:', 'निकास:', 'समाप्त:'],
    'Total:': ['Total:', 'कुल:', 'एकूण:'],
    'hours': ['hours', 'घंटे', 'तास'],
    'day': ['day', 'दिन', 'दिवस'],
    'days': ['days', 'दिन', 'दिवस'],
    'jobs selected': ['jobs selected', 'काम चुने गए', 'कामे निवडली'],
    'Value:': ['Value:', 'मूल्य:', 'मूल्य:'],
    'Cash submitted successfully to': [
      'Cash submitted successfully to',
      'नकद सफलतापूर्वक जमा हुआ',
      'रोख यशस्वीरित्या जमा झाले'
    ],
    'Job Details': ['Job Details', 'काम का विवरण', 'कामाचे तपशील'],
    'Are you sure you want to close this job? The job status will be updated to completed and you will be redirected to the home page.':
        [
      'Are you sure you want to close this job? The job status will be updated to completed and you will be redirected to the home page.',
      'क्या आप यह काम बंद करना चाहते हैं? काम की स्थिति पूरी हो जाएगी और आपको होम पेज पर भेज दिया जाएगा।',
      'तुम्हाला हे काम बंद करायचे आहे का? कामाची स्थिती पूर्ण होईल आणि तुम्हाला मुख्य पृष्ठावर नेले जाईल.',
    ],
    'Failed to start job': [
      'Failed to start job',
      'काम शुरू नहीं हो सका',
      'काम सुरू करता आले नाही'
    ],
    'Failed to close job': [
      'Failed to close job',
      'काम बंद नहीं हो सका',
      'काम बंद करता आले नाही'
    ],
    'Failed to grab job': [
      'Failed to grab job',
      'काम नहीं लिया जा सका',
      'काम घेता आले नाही'
    ],
    'Failed to download invoice': [
      'Failed to download invoice',
      'इनवॉइस डाउनलोड नहीं हुआ',
      'इनव्हॉइस डाउनलोड करता आले नाही'
    ],
    'Failed to view invoice': [
      'Failed to view invoice',
      'इनवॉइस नहीं देखा जा सका',
      'इनव्हॉइस पाहता आले नाही'
    ],
    'Error downloading invoice:': [
      'Error downloading invoice:',
      'इनवॉइस डाउनलोड करने में त्रुटि:',
      'इनव्हॉइस डाउनलोड करताना त्रुटी:'
    ],
    'Error viewing invoice:': [
      'Error viewing invoice:',
      'इनवॉइस देखने में त्रुटि:',
      'इनव्हॉइस पाहताना त्रुटी:'
    ],
    'Alternative Number': [
      'Alternative Number',
      'वैकल्पिक नंबर',
      'पर्यायी नंबर'
    ],
    'Flat Size': ['Flat Size', 'फ़्लैट का आकार', 'फ्लॅटचा आकार'],
    'Frequency': ['Frequency', 'आवृत्ति', 'वारंवारता'],
    'Warranty': ['Warranty', 'वारंटी', 'वॉरंटी'],
    'No. Of Visit': ['No. Of Visit', 'विज़िट की संख्या', 'भेटींची संख्या'],
    'Marketing Note': ['Marketing Note', 'मार्केटिंग नोट', 'मार्केटिंग नोंद'],
    'JOB START': ['JOB START', 'काम शुरू', 'काम सुरू'],
    'ALLOCATE TIME': ['ALLOCATE TIME', 'समय निर्धारित करें', 'वेळ निश्चित करा'],
    'Minutes': ['Minutes', 'मिनट', 'मिनिटे'],
    'Note:': ['Note:', 'नोट:', 'नोंद:'],
    'PAYMENT DESTINATION': [
      'PAYMENT DESTINATION',
      'भुगतान गंतव्य',
      'पेमेंटचे गंतव्य'
    ],
    'Loading payment destinations...': [
      'Loading payment destinations...',
      'भुगतान गंतव्य लोड हो रहे हैं...',
      'पेमेंटचे गंतव्य लोड होत आहेत...'
    ],
    'No payment destinations are available for this technician.': [
      'No payment destinations are available for this technician.',
      'इस तकनीशियन के लिए भुगतान गंतव्य उपलब्ध नहीं हैं।',
      'या तंत्रज्ञासाठी पेमेंटचे गंतव्य उपलब्ध नाहीत.'
    ],
    'Payment QR': ['Payment QR', 'भुगतान QR', 'पेमेंट QR'],
    'Please enter payment destination for the selected payment type': [
      'Please enter payment destination for the selected payment type',
      'चुने गए भुगतान प्रकार के लिए भुगतान गंतव्य दर्ज करें',
      'निवडलेल्या पेमेंट प्रकारासाठी पेमेंटचे गंतव्य भरा'
    ],
    'Failed to save payment': [
      'Failed to save payment',
      'भुगतान सहेजा नहीं जा सका',
      'पेमेंट जतन करता आले नाही'
    ],
    'Payment saved but failed to close job:': [
      'Payment saved but failed to close job:',
      'भुगतान सहेजा गया, लेकिन काम बंद नहीं हो सका:',
      'पेमेंट जतन झाले, पण काम बंद करता आले नाही:'
    ],
    'Branch ID:': ['Branch ID:', 'शाखा आईडी:', 'शाखा आयडी:'],
    'QR Available:': ['QR Available:', 'QR उपलब्ध:', 'QR उपलब्ध:'],
    'Loading:': ['Loading:', 'लोड हो रहा है:', 'लोड होत आहे:'],
    'QR URL:': ['QR URL:', 'QR URL:', 'QR URL:'],
    'Payment Name:': ['Payment Name:', 'भुगतान का नाम:', 'पेमेंटचे नाव:'],
    'UPI ID:': ['UPI ID:', 'UPI आईडी:', 'UPI आयडी:'],
    'minutes': ['minutes', 'मिनट', 'मिनिटे'],
    'Recurring Job': [
      'Recurring Job',
      'दोहराया जाने वाला काम',
      'पुनरावृत्तीचे काम'
    ],
    'Carry Forward Payment Active': [
      'Carry Forward Payment Active',
      'अग्रेषित भुगतान सक्रिय',
      'पुढे नेलेले पेमेंट सक्रिय'
    ],
    'PAID': ['PAID', 'भुगतान हो गया', 'पेमेंट झाले'],
    'PARTIAL': ['PARTIAL', 'आंशिक', 'अंशतः'],
    'PENDING': ['PENDING', 'बाकी', 'प्रलंबित'],
    'ALREADY PAID': [
      'ALREADY PAID',
      'पहले ही भुगतान हो चुका है',
      'आधीच पेमेंट झाले आहे'
    ],
    'Before Service Photos': [
      'Before Service Photos',
      'सेवा से पहले की फ़ोटो',
      'सेवेपूर्वीचे फोटो'
    ],
    'After Service Photos': [
      'After Service Photos',
      'सेवा के बाद की फ़ोटो',
      'सेवेनंतरचे फोटो'
    ],
    'BEFORE SERVICE PHOTOS': [
      'BEFORE SERVICE PHOTOS',
      'सेवा से पहले की फ़ोटो',
      'सेवेपूर्वीचे फोटो'
    ],
    'AFTER SERVICE PHOTOS': [
      'AFTER SERVICE PHOTOS',
      'सेवा के बाद की फ़ोटो',
      'सेवेनंतरचे फोटो'
    ],
    'Before & After Photos': [
      'Before & After Photos',
      'पहले और बाद की फ़ोटो',
      'आधीचे आणि नंतरचे फोटो'
    ],
    'No photos added yet': [
      'No photos added yet',
      'अभी तक कोई फ़ोटो नहीं जोड़ी गई',
      'अद्याप फोटो जोडलेले नाहीत'
    ],
    'UPLOAD BEFORE PHOTOS': [
      'UPLOAD BEFORE PHOTOS',
      'पहले की फ़ोटो अपलोड करें',
      'आधीचे फोटो अपलोड करा'
    ],
    'UPLOAD AFTER PHOTOS': [
      'UPLOAD AFTER PHOTOS',
      'बाद की फ़ोटो अपलोड करें',
      'नंतरचे फोटो अपलोड करा'
    ],
    'SIGNATURE PAD': [
      'SIGNATURE PAD',
      'हस्ताक्षर क्षेत्र',
      'स्वाक्षरी क्षेत्र'
    ],
    'Please ask the customer to sign below': [
      'Please ask the customer to sign below',
      'कृपया ग्राहक से नीचे हस्ताक्षर करने को कहें',
      'कृपया ग्राहकाला खाली स्वाक्षरी करण्यास सांगा'
    ],
    'Sign above with your finger': [
      'Sign above with your finger',
      'ऊपर अपनी उंगली से हस्ताक्षर करें',
      'वर बोटाने स्वाक्षरी करा'
    ],
    'SAVE SIGNATURE': [
      'SAVE SIGNATURE',
      'हस्ताक्षर सहेजें',
      'स्वाक्षरी जतन करा'
    ],
    'Failed to capture signature': [
      'Failed to capture signature',
      'हस्ताक्षर कैप्चर नहीं हो सके',
      'स्वाक्षरी कॅप्चर करता आली नाही'
    ],
    'Failed to upload signature': [
      'Failed to upload signature',
      'हस्ताक्षर अपलोड नहीं हो सके',
      'स्वाक्षरी अपलोड करता आली नाही'
    ],
    'Check In Equipment': [
      'Check In Equipment',
      'उपकरण जमा करें',
      'साहित्य जमा करा'
    ],
    'Check Out Equipment': [
      'Check Out Equipment',
      'उपकरण निकालें',
      'साहित्य बाहेर न्या'
    ],
    'Equipment Checklist': [
      'Equipment Checklist',
      'उपकरण जाँच सूची',
      'साहित्य तपासणी यादी'
    ],
    'CONFIRM BAG IN': [
      'CONFIRM BAG IN',
      'बैग जमा की पुष्टि करें',
      'बॅग जमा केल्याची पुष्टी करा'
    ],
    'CONFIRM BAG OUT': [
      'CONFIRM BAG OUT',
      'बैग निकासी की पुष्टि करें',
      'बॅग बाहेर नेल्याची पुष्टी करा'
    ],
    'Qty:': ['Qty:', 'मात्रा:', 'प्रमाण:'],
    'Sprayer': ['Sprayer', 'स्प्रेयर', 'फवारणी यंत्र'],
    'Safety Mask': ['Safety Mask', 'सुरक्षा मास्क', 'सुरक्षा मास्क'],
    'Gloves': ['Gloves', 'दस्ताने', 'हातमोजे'],
    'Torch': ['Torch', 'टॉर्च', 'टॉर्च'],
    'Tools Kit': ['Tools Kit', 'उपकरण किट', 'साधनांचा संच'],
    'Add-On Services': ['Add-On Services', 'अतिरिक्त सेवाएँ', 'अतिरिक्त सेवा'],
    'Failed to add services': [
      'Failed to add services',
      'सेवाएँ नहीं जोड़ी जा सकीं',
      'सेवा जोडता आल्या नाहीत'
    ],
    'Upload failed': ['Upload failed', 'अपलोड विफल हुआ', 'अपलोड अयशस्वी झाले'],
    'Failed to upload photos': [
      'Failed to upload photos',
      'फ़ोटो अपलोड नहीं हुईं',
      'फोटो अपलोड करता आले नाहीत'
    ],
    'photo': ['photo', 'फ़ोटो', 'फोटो'],
    'photos': ['photos', 'फ़ोटो', 'फोटो'],
    'Error taking photo:': [
      'Error taking photo:',
      'फ़ोटो लेने में त्रुटि:',
      'फोटो काढताना त्रुटी:'
    ],
    'Error uploading photos:': [
      'Error uploading photos:',
      'फ़ोटो अपलोड करने में त्रुटि:',
      'फोटो अपलोड करताना त्रुटी:'
    ],
    'Bag in completed successfully!': [
      'Bag in completed successfully!',
      'बैग जमा सफलतापूर्वक हुआ!',
      'बॅग जमा करणे यशस्वीरित्या पूर्ण झाले!'
    ],
    'Bag out completed successfully!': [
      'Bag out completed successfully!',
      'बैग निकासी सफलतापूर्वक हुई!',
      'बॅग बाहेर नेणे यशस्वीरित्या पूर्ण झाले!'
    ],
    'Advance Balance': [
      'Advance Balance',
      'अग्रिम शेष राशि',
      'अॅडव्हान्स शिल्लक'
    ],
    'Remaining Balance': ['Remaining Balance', 'शेष राशि', 'शिल्लक रक्कम'],
    'Monthly Budget': ['Monthly Budget', 'मासिक बजट', 'मासिक बजेट'],
    'Not provided': ['Not provided', 'उपलब्ध नहीं', 'दिलेली नाही'],
    'Address Information': [
      'Address Information',
      'पते की जानकारी',
      'पत्त्याची माहिती'
    ],
    'My Reference': ['My Reference', 'मेरा संदर्भ', 'माझा संदर्भ'],
    'This Month\'s Expenses': [
      'This Month\'s Expenses',
      'इस महीने के खर्च',
      'या महिन्याचा खर्च'
    ],
    'No expenses added today': [
      'No expenses added today',
      'आज कोई खर्च नहीं जोड़ा गया',
      'आज कोणताही खर्च जोडलेला नाही'
    ],
    'Receipt attached': [
      'Receipt attached',
      'रसीद संलग्न है',
      'पावती जोडली आहे'
    ],
    'Expense status': ['Expense status', 'खर्च की स्थिति', 'खर्चाची स्थिती'],
    'Approved': ['Approved', 'स्वीकृत', 'मंजूर'],
    'Rejected': ['Rejected', 'अस्वीकृत', 'नामंजूर'],
    'Admin note:': ['Admin note:', 'एडमिन नोट:', 'अॅडमिन नोंद:'],
    'FULLY PAID': ['FULLY PAID', 'पूरा भुगतान हुआ', 'पूर्ण पेमेंट झाले'],
    'PARTIALLY PAID': [
      'PARTIALLY PAID',
      'आंशिक भुगतान हुआ',
      'अंशतः पेमेंट झाले'
    ],
    'PAYMENT PENDING': [
      'PAYMENT PENDING',
      'भुगतान बाकी है',
      'पेमेंट प्रलंबित आहे'
    ],
    'Customer paid in advance': [
      'Customer paid in advance',
      'ग्राहक ने अग्रिम भुगतान किया',
      'ग्राहकाने आगाऊ पेमेंट केले'
    ],
    'Base Amount:': ['Base Amount:', 'मूल राशि:', 'मूळ रक्कम:'],
    'Total Amount:': ['Total Amount:', 'कुल राशि:', 'एकूण रक्कम:'],
    'Paid Amount:': ['Paid Amount:', 'भुगतान राशि:', 'भरलेली रक्कम:'],
    'Pending Amount:': ['Pending Amount:', 'बाकी राशि:', 'बाकी रक्कम:'],
    'SELECT PAYMENT TYPE': [
      'SELECT PAYMENT TYPE',
      'भुगतान प्रकार चुनें',
      'पेमेंट प्रकार निवडा'
    ],
    'ACCEPT CASH': ['ACCEPT CASH', 'नकद स्वीकारें', 'रोख स्वीकारा'],
    'ONLINE / QR': ['ONLINE / QR', 'ऑनलाइन / QR', 'ऑनलाइन / QR'],
    'CHEQUE': ['CHEQUE', 'चेक', 'धनादेश'],
    'Amount cannot exceed pending amount': [
      'Amount cannot exceed pending amount',
      'राशि लंबित राशि से अधिक नहीं हो सकती',
      'रक्कम बाकी रकमेपेक्षा जास्त असू शकत नाही'
    ],
    'Generating PDF receipt...': [
      'Generating PDF receipt...',
      'PDF रसीद बनाई जा रही है...',
      'PDF पावती तयार होत आहे...'
    ],
    'Job completed successfully! (Payment already received)': [
      'Job completed successfully! (Payment already received)',
      'काम पूरा हुआ! (भुगतान पहले ही मिल चुका है)',
      'काम पूर्ण झाले! (पेमेंट आधीच मिळाले आहे)'
    ],
    'Payment received successfully. Would you like to send a receipt to the customer?':
        [
      'Payment received successfully. Would you like to send a receipt to the customer?',
      'भुगतान सफलतापूर्वक मिला। क्या आप ग्राहक को रसीद भेजना चाहते हैं?',
      'पेमेंट यशस्वीरित्या मिळाले. ग्राहकाला पावती पाठवायची आहे का?'
    ],
    'Account created successfully!': [
      'Account created successfully!',
      'खाता सफलतापूर्वक बनाया गया!',
      'खाते यशस्वीरित्या तयार झाले!'
    ],
    'Add additional services performed during this job': [
      'Add additional services performed during this job',
      'इस काम के दौरान दी गई अतिरिक्त सेवाएँ जोड़ें',
      'या कामादरम्यान दिलेल्या अतिरिक्त सेवा जोडा'
    ],
    'Add Another Service': [
      'Add Another Service',
      'एक और सेवा जोड़ें',
      'आणखी एक सेवा जोडा'
    ],
    'Add-on services updated! Total amount refreshed.': [
      'Add-on services updated! Total amount refreshed.',
      'अतिरिक्त सेवाएँ अपडेट हुईं! कुल राशि अपडेट की गई।',
      'अतिरिक्त सेवा अपडेट झाल्या! एकूण रक्कम अपडेट झाली.'
    ],
    'Add-On Services:': [
      'Add-On Services:',
      'अतिरिक्त सेवाएँ:',
      'अतिरिक्त सेवा:'
    ],
    'After Payment': ['After Payment', 'भुगतान के बाद', 'पेमेंटनंतर'],
    'After photos marked as uploaded': [
      'After photos marked as uploaded',
      'बाद की फ़ोटो अपलोड की गई के रूप में चिह्नित हुईं',
      'नंतरचे फोटो अपलोड केल्याची नोंद झाली'
    ],
    'After photos uploaded!': [
      'After photos uploaded!',
      'बाद की फ़ोटो अपलोड हुईं!',
      'नंतरचे फोटो अपलोड झाले!'
    ],
    'All cash has been submitted!': [
      'All cash has been submitted!',
      'सारी नकदी जमा कर दी गई है!',
      'सर्व रोख रक्कम जमा केली आहे!'
    ],
    'Already have an account? ': [
      'Already have an account? ',
      'पहले से खाता है? ',
      'आधीपासून खाते आहे? '
    ],
    'Already Recorded': [
      'Already Recorded',
      'पहले से दर्ज है',
      'आधीच नोंदवले आहे'
    ],
    'API Base URL': ['API Base URL', 'API का आधार URL', 'API चा बेस URL'],
    'Are you sure you want to logout?': [
      'Are you sure you want to logout?',
      'क्या आप लॉग आउट करना चाहते हैं?',
      'तुम्हाला लॉग आउट करायचे आहे का?'
    ],
    'Before photos marked as uploaded': [
      'Before photos marked as uploaded',
      'पहले की फ़ोटो अपलोड की गई के रूप में चिह्नित हुईं',
      'आधीचे फोटो अपलोड केल्याची नोंद झाली'
    ],
    'Before photos uploaded! Now upload after photos.': [
      'Before photos uploaded! Now upload after photos.',
      'पहले की फ़ोटो अपलोड हुईं! अब बाद की फ़ोटो अपलोड करें।',
      'आधीचे फोटो अपलोड झाले! आता नंतरचे फोटो अपलोड करा.'
    ],
    'Camera permission permanently denied. Please enable it in settings.': [
      'Camera permission permanently denied. Please enable it in settings.',
      'कैमरे की अनुमति हमेशा के लिए अस्वीकृत है। कृपया सेटिंग में इसे चालू करें।',
      'कॅमेराची परवानगी कायमची नाकारली आहे. कृपया सेटिंग्जमध्ये ती सुरू करा.'
    ],
    'Capture a photo of the payment receipt or transaction screenshot': [
      'Capture a photo of the payment receipt or transaction screenshot',
      'भुगतान रसीद या लेन-देन के स्क्रीनशॉट की फ़ोटो लें',
      'पेमेंट पावती किंवा व्यवहाराच्या स्क्रीनशॉटचा फोटो काढा'
    ],
    'Click the button below to add services': [
      'Click the button below to add services',
      'सेवाएँ जोड़ने के लिए नीचे दिए गए बटन पर टैप करें',
      'सेवा जोडण्यासाठी खालील बटणावर टॅप करा'
    ],
    'Close': ['Close', 'बंद करें', 'बंद करा'],
    'Complete & Reschedule': [
      'Complete & Reschedule',
      'पूरा करें और फिर से शेड्यूल करें',
      'पूर्ण करा आणि पुन्हा वेळ ठरवा'
    ],
    'COMPLETE & RESCHEDULE': [
      'COMPLETE & RESCHEDULE',
      'पूरा करें और फिर से शेड्यूल करें',
      'पूर्ण करा आणि पुन्हा वेळ ठरवा'
    ],
    'COMPLETE JOB': ['COMPLETE JOB', 'काम पूरा करें', 'काम पूर्ण करा'],
    'COMPLETE': ['COMPLETE', 'पूरा करें', 'पूर्ण करा'],
    'CAPTURE PAYMENT PROOF': [
      'CAPTURE PAYMENT PROOF',
      'भुगतान का प्रमाण लें',
      'पेमेंटचा पुरावा घ्या',
    ],
    'Opening Camera...': [
      'Opening Camera...',
      'कैमरा खुल रहा है...',
      'कॅमेरा उघडत आहे...',
    ],
    'ADD ON SERVICE': [
      'ADD ON SERVICE',
      'अतिरिक्त सेवा जोड़ें',
      'अतिरिक्त सेवा जोडा',
    ],
    'PAYMENT OPTION': [
      'PAYMENT OPTION',
      'भुगतान विकल्प',
      'पेमेंट पर्याय',
    ],
    'Complete the property survey before submitting.': [
      'Complete the property survey before submitting.',
      'जमा करने से पहले संपत्ति का सर्वे पूरा करें।',
      'सबमिट करण्यापूर्वी मालमत्तेचे सर्वेक्षण पूर्ण करा.'
    ],
    'Configuration': ['Configuration', 'कॉन्फ़िगरेशन', 'कॉन्फिगरेशन'],
    'Confirm': ['Confirm', 'पुष्टि करें', 'पुष्टी करा'],
    'Confirm conversion': [
      'Confirm conversion',
      'रूपांतरण की पुष्टि करें',
      'रूपांतरणाची पुष्टी करा'
    ],
    'Conversation': ['Conversation', 'बातचीत', 'संभाषण'],
    'Converted': ['Converted', 'रूपांतरित', 'रूपांतरित'],
    'Could not open WhatsApp. Please make sure it is installed.': [
      'Could not open WhatsApp. Please make sure it is installed.',
      'WhatsApp नहीं खुल सका। कृपया जाँचें कि यह इंस्टॉल है।',
      'WhatsApp उघडता आले नाही. कृपया ते इंस्टॉल असल्याची खात्री करा.'
    ],
    'CREATE ACCOUNT': ['CREATE ACCOUNT', 'खाता बनाएँ', 'खाते तयार करा'],
    'Create your technician account': [
      'Create your technician account',
      'अपना तकनीशियन खाता बनाएँ',
      'तुमचे तंत्रज्ञ खाते तयार करा'
    ],
    'Current Environment': [
      'Current Environment',
      'वर्तमान परिवेश',
      'सध्याचे वातावरण'
    ],
    'CUSTOMER DETAILS': [
      'CUSTOMER DETAILS',
      'ग्राहक का विवरण',
      'ग्राहकाचे तपशील'
    ],
    'Data refreshed successfully!': [
      'Data refreshed successfully!',
      'डेटा सफलतापूर्वक रीफ़्रेश हुआ!',
      'डेटा यशस्वीरित्या रिफ्रेश झाला!'
    ],
    'Error: Technician ID is invalid. Please refresh and try again.': [
      'Error: Technician ID is invalid. Please refresh and try again.',
      'त्रुटि: तकनीशियन आईडी अमान्य है। कृपया रीफ़्रेश करके फिर कोशिश करें।',
      'त्रुटी: तंत्रज्ञ आयडी अवैध आहे. कृपया रिफ्रेश करून पुन्हा प्रयत्न करा.'
    ],
    'Expense added successfully': [
      'Expense added successfully',
      'खर्च सफलतापूर्वक जोड़ा गया',
      'खर्च यशस्वीरित्या जोडला'
    ],
    'Failed to load QR code': [
      'Failed to load QR code',
      'QR कोड लोड नहीं हो सका',
      'QR कोड लोड करता आला नाही'
    ],
    'FIELD INBOX': ['FIELD INBOX', 'फील्ड इनबॉक्स', 'फील्ड इनबॉक्स'],
    'For any queries, please contact us': [
      'For any queries, please contact us',
      'किसी भी प्रश्न के लिए कृपया हमसे संपर्क करें',
      'काही प्रश्न असल्यास कृपया आमच्याशी संपर्क साधा'
    ],
    'History': ['History', 'इतिहास', 'इतिहास'],
    'How to Change': ['How to Change', 'कैसे बदलें', 'कसे बदलावे'],
    'Image size too large (max 5MB). Please select a smaller image.': [
      'Image size too large (max 5MB). Please select a smaller image.',
      'छवि बहुत बड़ी है (अधिकतम 5MB)। कृपया छोटी छवि चुनें।',
      'प्रतिमा खूप मोठी आहे (कमाल 5MB). कृपया लहान प्रतिमा निवडा.'
    ],
    'Leave History': ['Leave History', 'छुट्टी का इतिहास', 'रजेचा इतिहास'],
    'Loading QR Code...': [
      'Loading QR Code...',
      'QR कोड लोड हो रहा है...',
      'QR कोड लोड होत आहे...'
    ],
    'Login': ['Login', 'लॉगिन', 'लॉगिन'],
    'Logout failed. Please try again.': [
      'Logout failed. Please try again.',
      'लॉग आउट नहीं हो सका। कृपया फिर कोशिश करें।',
      'लॉग आउट करता आले नाही. कृपया पुन्हा प्रयत्न करा.'
    ],
    'Mark After Photos as Uploaded': [
      'Mark After Photos as Uploaded',
      'बाद की फ़ोटो को अपलोड किया हुआ चिह्नित करें',
      'नंतरचे फोटो अपलोड केल्याचे चिन्हांकित करा'
    ],
    'Mark Before Photos as Uploaded': [
      'Mark Before Photos as Uploaded',
      'पहले की फ़ोटो को अपलोड किया हुआ चिह्नित करें',
      'आधीचे फोटो अपलोड केल्याचे चिन्हांकित करा'
    ],
    'Mark Signature as Uploaded': [
      'Mark Signature as Uploaded',
      'हस्ताक्षर को अपलोड किया हुआ चिह्नित करें',
      'स्वाक्षरी अपलोड केल्याचे चिन्हांकित करा'
    ],
    'New conversations will appear here.': [
      'New conversations will appear here.',
      'नई बातचीत यहाँ दिखाई देगी।',
      'नवीन संभाषणे येथे दिसतील.'
    ],
    'No add-on services yet': [
      'No add-on services yet',
      'अभी कोई अतिरिक्त सेवा नहीं है',
      'अद्याप कोणतीही अतिरिक्त सेवा नाही'
    ],
    'No entries in this period.': [
      'No entries in this period.',
      'इस अवधि में कोई प्रविष्टि नहीं है।',
      'या कालावधीत कोणतीही नोंद नाही.'
    ],
    'No leave requests found': [
      'No leave requests found',
      'छुट्टी के अनुरोध नहीं मिले',
      'रजेचे अर्ज आढळले नाहीत'
    ],
    'No messages yet': [
      'No messages yet',
      'अभी कोई संदेश नहीं है',
      'अद्याप संदेश नाहीत'
    ],
    'No Pending Cash': [
      'No Pending Cash',
      'कोई नकदी बाकी नहीं है',
      'कोणतीही रोख रक्कम बाकी नाही'
    ],
    'OK': ['OK', 'ठीक है', 'ठीक आहे'],
    'Opening WhatsApp...': [
      'Opening WhatsApp...',
      'WhatsApp खुल रहा है...',
      'WhatsApp उघडत आहे...'
    ],
    'Passwords do not match': [
      'Passwords do not match',
      'पासवर्ड मेल नहीं खाते',
      'पासवर्ड जुळत नाहीत'
    ],
    'PAYMENT COMPLETE': [
      'PAYMENT COMPLETE',
      'भुगतान पूरा हुआ',
      'पेमेंट पूर्ण झाले'
    ],
    'PAYMENT DETAILS': ['PAYMENT DETAILS', 'भुगतान का विवरण', 'पेमेंटचे तपशील'],
    'PAYMENT PROOF': ['PAYMENT PROOF', 'भुगतान का प्रमाण', 'पेमेंटचा पुरावा'],
    'PAYMENT RECEIPT': ['PAYMENT RECEIPT', 'भुगतान की रसीद', 'पेमेंटची पावती'],
    'PDF receipt generated successfully!': [
      'PDF receipt generated successfully!',
      'PDF रसीद सफलतापूर्वक बनाई गई!',
      'PDF पावती यशस्वीरित्या तयार झाली!'
    ],
    'Pending balance': ['Pending balance', 'बाकी राशि', 'बाकी शिल्लक'],
    'PENDING JOBS': ['PENDING JOBS', 'बाकी काम', 'प्रलंबित कामे'],
    'Pest Control Services': [
      'Pest Control Services',
      'कीट नियंत्रण सेवाएँ',
      'कीटक नियंत्रण सेवा'
    ],
    'PEST CONTROL SOLUTIONS': [
      'PEST CONTROL SOLUTIONS',
      'कीट नियंत्रण समाधान',
      'कीटक नियंत्रण उपाय'
    ],
    'Petrol Allowance': ['Petrol Allowance', 'पेट्रोल भत्ता', 'पेट्रोल भत्ता'],
    'Please contact admin to upload QR code for this branch': [
      'Please contact admin to upload QR code for this branch',
      'इस शाखा के लिए QR कोड अपलोड करने हेतु एडमिन से संपर्क करें',
      'या शाखेसाठी QR कोड अपलोड करण्यासाठी अॅडमिनशी संपर्क साधा'
    ],
    'Please enter kilometer reading': [
      'Please enter kilometer reading',
      'कृपया किलोमीटर रीडिंग दर्ज करें',
      'कृपया किलोमीटर रीडिंग भरा'
    ],
    'Please enter paid amount first': [
      'Please enter paid amount first',
      'कृपया पहले भुगतान की राशि दर्ज करें',
      'कृपया आधी भरलेली रक्कम भरा'
    ],
    'Please select date and time': [
      'Please select date and time',
      'कृपया तारीख और समय चुनें',
      'कृपया तारीख आणि वेळ निवडा'
    ],
    'Please select payment mode first': [
      'Please select payment mode first',
      'कृपया पहले भुगतान का तरीका चुनें',
      'कृपया आधी पेमेंटचा प्रकार निवडा'
    ],
    'PREVIEW': ['PREVIEW', 'पूर्वावलोकन', 'पूर्वदृश्य'],
    'Professional Technician Application': [
      'Professional Technician Application',
      'तकनीशियन के लिए पेशेवर ऐप',
      'तंत्रज्ञांसाठी व्यावसायिक अॅप'
    ],
    'Property survey': [
      'Property survey',
      'संपत्ति का सर्वेक्षण',
      'मालमत्तेचे सर्वेक्षण'
    ],
    'QR Code Not Available': [
      'QR Code Not Available',
      'QR कोड उपलब्ध नहीं है',
      'QR कोड उपलब्ध नाही'
    ],
    'Reading:': ['Reading:', 'रीडिंग:', 'रीडिंग:'],
    'Receipt Photo': ['Receipt Photo', 'रसीद की फ़ोटो', 'पावतीचा फोटो'],
    'Recent Records': [
      'Recent Records',
      'हाल की प्रविष्टियाँ',
      'अलीकडील नोंदी'
    ],
    'Redirecting to home...': [
      'Redirecting to home...',
      'होम पेज पर जा रहे हैं...',
      'मुख्य पृष्ठावर जात आहे...'
    ],
    'Reschedule Date & Time': [
      'Reschedule Date & Time',
      'नई तारीख और समय तय करें',
      'नवीन तारीख आणि वेळ ठरवा'
    ],
    'Revisit Date': [
      'Revisit Date',
      'दोबारा आने की तारीख',
      'पुन्हा भेटीची तारीख'
    ],
    'Revisit Scheduled!': [
      'Revisit Scheduled!',
      'दोबारा आने का समय तय हुआ!',
      'पुन्हा भेटीची वेळ ठरली!'
    ],
    'Revisit Time': ['Revisit Time', 'दोबारा आने का समय', 'पुन्हा भेटीची वेळ'],
    'SAVE ADD-ON SERVICES': [
      'SAVE ADD-ON SERVICES',
      'अतिरिक्त सेवाएँ सहेजें',
      'अतिरिक्त सेवा जतन करा'
    ],
    'Scan QR to Pay': [
      'Scan QR to Pay',
      'भुगतान के लिए QR स्कैन करें',
      'पेमेंट करण्यासाठी QR स्कॅन करा'
    ],
    'Scan this QR Code': [
      'Scan this QR Code',
      'यह QR कोड स्कैन करें',
      'हा QR कोड स्कॅन करा'
    ],
    'Schedule': ['Schedule', 'समय-सारणी', 'वेळापत्रक'],
    'Schedule a follow-up visit for incomplete work': [
      'Schedule a follow-up visit for incomplete work',
      'अधूरे काम के लिए अगली मुलाक़ात तय करें',
      'अपूर्ण कामासाठी पुढील भेटीची वेळ ठरवा'
    ],
    'Schedule Revisit': [
      'Schedule Revisit',
      'दोबारा आने का समय तय करें',
      'पुन्हा भेटीची वेळ ठरवा'
    ],
    'Send an update to begin.': [
      'Send an update to begin.',
      'शुरू करने के लिए अपडेट भेजें।',
      'सुरू करण्यासाठी अपडेट पाठवा.'
    ],
    'Signature marked as uploaded': [
      'Signature marked as uploaded',
      'हस्ताक्षर अपलोड किए हुए के रूप में चिह्नित हुए',
      'स्वाक्षरी अपलोड केल्याची नोंद झाली'
    ],
    'Signature uploaded!': [
      'Signature uploaded!',
      'हस्ताक्षर अपलोड हुए!',
      'स्वाक्षरी अपलोड झाली!'
    ],
    'START JOB': ['START JOB', 'काम शुरू करें', 'काम सुरू करा'],
    'Survey Form': ['Survey Form', 'सर्वे फ़ॉर्म', 'सर्वेक्षण फॉर्म'],
    'Survey Jobs': ['Survey Jobs', 'सर्वे के काम', 'सर्वेक्षणाची कामे'],
    'Survey status': [
      'Survey status',
      'सर्वे की स्थिति',
      'सर्वेक्षणाची स्थिती'
    ],
    'Tap to copy': [
      'Tap to copy',
      'कॉपी करने के लिए टैप करें',
      'कॉपी करण्यासाठी टॅप करा'
    ],
    'Technician ID not found': [
      'Technician ID not found',
      'तकनीशियन आईडी नहीं मिली',
      'तंत्रज्ञ आयडी सापडली नाही'
    ],
    'Test Connection': ['Test Connection', 'कनेक्शन जाँचें', 'कनेक्शन तपासा'],
    'Test connection feature coming soon!': [
      'Test connection feature coming soon!',
      'कनेक्शन जाँचने की सुविधा जल्द आ रही है!',
      'कनेक्शन तपासण्याची सुविधा लवकरच येत आहे!'
    ],
    'Thank you for your business!': [
      'Thank you for your business!',
      'आपके व्यवसाय के लिए धन्यवाद!',
      'आपल्या व्यवसायाबद्दल धन्यवाद!'
    ],
    'The revisit has been scheduled successfully.': [
      'The revisit has been scheduled successfully.',
      'दोबारा आने का समय सफलतापूर्वक तय हुआ।',
      'पुन्हा भेटीची वेळ यशस्वीरित्या ठरवली.'
    ],
    'This marks the lead as converted and automatically creates a draft quotation.':
        [
      'This marks the lead as converted and automatically creates a draft quotation.',
      'इससे लीड रूपांतरित हो जाएगी और अपने-आप एक प्रारूप कोटेशन बनेगा।',
      'यामुळे लीड रूपांतरित होईल आणि आपोआप कोटेशनचा मसुदा तयार होईल.'
    ],
    'This visit will appear in the Marketing App\'s Visit tab.': [
      'This visit will appear in the Marketing App\'s Visit tab.',
      'यह मुलाक़ात मार्केटिंग ऐप के विज़िट टैब में दिखाई देगी।',
      'ही भेट मार्केटिंग अॅपच्या भेटी टॅबमध्ये दिसेल.'
    ],
    'This will:': ['This will:', 'इससे:', 'यामुळे:'],
    'Time:': ['Time:', 'समय:', 'वेळ:'],
    'Upload screenshot below': [
      'Upload screenshot below',
      'नीचे स्क्रीनशॉट अपलोड करें',
      'खाली स्क्रीनशॉट अपलोड करा'
    ],
    'User data not found. Please login again.': [
      'User data not found. Please login again.',
      'उपयोगकर्ता का डेटा नहीं मिला। कृपया फिर से लॉगिन करें।',
      'वापरकर्त्याचा डेटा सापडला नाही. कृपया पुन्हा लॉगिन करा.'
    ],
    'User ID not found. Please login again.': [
      'User ID not found. Please login again.',
      'उपयोगकर्ता आईडी नहीं मिली। कृपया फिर से लॉगिन करें।',
      'वापरकर्ता आयडी सापडली नाही. कृपया पुन्हा लॉगिन करा.'
    ],
    'View': ['View', 'देखें', 'पहा'],
    'Waiting for Confirmation': [
      'Waiting for Confirmation',
      'पुष्टि की प्रतीक्षा है',
      'पुष्टीची प्रतीक्षा आहे'
    ],
    'Welcome back': ['Welcome back', 'वापसी पर स्वागत है', 'पुन्हा स्वागत आहे'],
    'You cannot receive new job assignments during this period.': [
      'You cannot receive new job assignments during this period.',
      'इस अवधि में आपको नए काम नहीं दिए जा सकते।',
      'या कालावधीत तुम्हाला नवीन कामे दिली जाऊ शकत नाहीत.'
    ],
    'Your inbox is clear': [
      'Your inbox is clear',
      'आपका इनबॉक्स खाली है',
      'तुमचा इनबॉक्स रिकामा आहे'
    ],
    'Day': ['Day', 'दिन', 'दिवस'],
    'Week': ['Week', 'सप्ताह', 'आठवडा'],
    'Month': ['Month', 'महीना', 'महिना'],
    'Year': ['Year', 'वर्ष', 'वर्ष'],
    'Custom': ['Custom', 'कस्टम', 'सानुकूल'],
    'Refresh surveys': [
      'Refresh surveys',
      'सर्वे रीफ़्रेश करें',
      'सर्वेक्षण रिफ्रेश करा'
    ],
    'Unknown date': ['Unknown date', 'अज्ञात तारीख', 'अज्ञात तारीख'],
    'Amount received': ['Amount received', 'प्राप्त राशि', 'मिळालेली रक्कम'],
    'Given all time': ['Given all time', 'अब तक दिया गया', 'आतापर्यंत दिलेले'],
    'Used all time': [
      'Used all time',
      'अब तक उपयोग किया',
      'आतापर्यंत वापरलेले'
    ],
    'Balance': ['Balance', 'शेष राशि', 'शिल्लक'],
    'Amount given': ['Amount given', 'दी गई राशि', 'दिलेली रक्कम'],
    'Km travelled': ['Km travelled', 'कुल दूरी (किमी)', 'प्रवास (किमी)'],
    'Period net': ['Period net', 'अवधि का शुद्ध योग', 'कालावधीची निव्वळ रक्कम'],
    'Amount to Pay': ['Amount to Pay', 'भुगतान की राशि', 'द्यायची रक्कम'],
    'Select time': ['Select time', 'समय चुनें', 'वेळ निवडा'],
    'Flat size (ERP)': [
      'Flat size (ERP)',
      'फ़्लैट का आकार (ERP)',
      'फ्लॅटचा आकार (ERP)'
    ],
    'Infestation level': [
      'Infestation level',
      'संक्रमण का स्तर',
      'प्रादुर्भावाची पातळी'
    ],
    'Affected areas': ['Affected areas', 'प्रभावित क्षेत्र', 'प्रभावित भाग'],
    'For example: kitchen and balcony': [
      'For example: kitchen and balcony',
      'उदाहरण: रसोई और बालकनी',
      'उदाहरणार्थ: स्वयंपाकघर आणि बाल्कनी'
    ],
    'Findings and recommendation (optional)': [
      'Findings and recommendation (optional)',
      'निष्कर्ष और सुझाव (वैकल्पिक)',
      'निरीक्षणे आणि शिफारस (ऐच्छिक)'
    ],
    'Proposed service date': [
      'Proposed service date',
      'प्रस्तावित सेवा तारीख',
      'प्रस्तावित सेवा तारीख'
    ],
    'Proposed service time': [
      'Proposed service time',
      'प्रस्तावित सेवा समय',
      'प्रस्तावित सेवा वेळ'
    ],
    'Unable to start chat': [
      'Unable to start chat',
      'चैट शुरू नहीं हो सकी',
      'चॅट सुरू करता आली नाही'
    ],
    'Unable to send message': [
      'Unable to send message',
      'संदेश नहीं भेजा जा सका',
      'संदेश पाठवता आला नाही'
    ],
    'Surveys unavailable': [
      'Surveys unavailable',
      'सर्वे उपलब्ध नहीं हैं',
      'सर्वेक्षण उपलब्ध नाही'
    ],
    'No survey jobs': [
      'No survey jobs',
      'सर्वे का कोई काम नहीं है',
      'सर्वेक्षणाची कामे नाहीत'
    ],
    'Assigned survey jobs will appear here.': [
      'Assigned survey jobs will appear here.',
      'दिए गए सर्वे के काम यहाँ दिखाई देंगे।',
      'नेमलेली सर्वेक्षणाची कामे येथे दिसतील.'
    ],
    'Could not load survey jobs.': [
      'Could not load survey jobs.',
      'सर्वे के काम लोड नहीं हो सके।',
      'सर्वेक्षणाची कामे लोड करता आली नाहीत.'
    ],
    'Technician account could not be identified.': [
      'Technician account could not be identified.',
      'तकनीशियन का खाता नहीं पहचाना जा सका।',
      'तंत्रज्ञाचे खाते ओळखता आले नाही.'
    ],
    'A valid GPS location is required. Please try again.': [
      'A valid GPS location is required. Please try again.',
      'GPS का सही स्थान आवश्यक है। कृपया फिर कोशिश करें।',
      'GPS चे वैध स्थान आवश्यक आहे. कृपया पुन्हा प्रयत्न करा.'
    ],
    'Advance request submitted successfully!': [
      'Advance request submitted successfully!',
      'अग्रिम का अनुरोध सफलतापूर्वक जमा हुआ!',
      'अॅडव्हान्सची विनंती यशस्वीरित्या सबमिट झाली!'
    ],
    'Captured': ['Captured', 'कैप्चर किया गया', 'कॅप्चर केले'],
    'Clear': ['Clear', 'साफ़ करें', 'पुसून टाका'],
    'High': ['High', 'उच्च', 'जास्त'],
    'Low': ['Low', 'कम', 'कमी'],
    'Medium': ['Medium', 'मध्यम', 'मध्यम'],
    'ACTIVE': ['ACTIVE', 'सक्रिय', 'सक्रिय'],
    '1. Complete current job with payment\n2. Create new rescheduled job\n3. Both jobs will appear in system':
        [
      '1. Complete current job with payment\n2. Create new rescheduled job\n3. Both jobs will appear in system',
      '1. भुगतान लेकर मौजूदा काम पूरा करें\n2. नई तारीख वाला काम बनाएँ\n3. दोनों काम सिस्टम में दिखाई देंगे',
      '1. पेमेंट घेऊन सध्याचे काम पूर्ण करा\n2. नवीन वेळेचे काम तयार करा\n3. दोन्ही कामे सिस्टममध्ये दिसतील',
    ],
    'To change the environment:\n\n': [
      'To change the environment:\n\n',
      'वातावरण बदलने के लिए:\n\n',
      'वातावरण बदलण्यासाठी:\n\n',
    ],
    'Petrol allowance': ['Petrol allowance', 'पेट्रोल भत्ता', 'पेट्रोल भत्ता'],
    'Technician update': [
      'Technician update',
      'तकनीशियन अपडेट',
      'तंत्रज्ञ अपडेट'
    ],
    'You have a new update.': [
      'You have a new update.',
      'आपके लिए नया अपडेट है।',
      'तुमच्यासाठी नवीन अपडेट आहे.'
    ],
    'Technician activity': [
      'Technician activity',
      'तकनीशियन गतिविधि',
      'तंत्रज्ञ गतिविधी'
    ],
    'Updates about technician jobs and schedule changes.': [
      'Updates about technician jobs and schedule changes.',
      'तकनीशियन के काम और समय-सारणी में बदलाव के अपडेट।',
      'तंत्रज्ञांच्या कामांतील आणि वेळापत्रकातील बदलांचे अपडेट.',
    ],
    'trips': ['trips', 'यात्राएँ', 'फेऱ्या'],
    'Full Name': ['Full Name', 'पूरा नाम', 'पूर्ण नाव'],
    'Email Address': ['Email Address', 'ईमेल पता', 'ईमेल पत्ता'],
    'Technician Chat': ['Technician Chat', 'तकनीशियन चैट', 'तंत्रज्ञ चॅट'],
    'Welcome': ['Welcome', 'स्वागत है', 'स्वागत आहे'],
    'Service': ['Service', 'सेवा', 'सेवा'],
    'Odometer Photo': ['Odometer Photo', 'ओडोमीटर की फ़ोटो', 'ओडोमीटरचा फोटो'],
    'Optional': ['Optional', 'वैकल्पिक', 'ऐच्छिक'],
    'Branch / Location:': [
      'Branch / Location:',
      'शाखा / स्थान:',
      'शाखा / ठिकाण:',
    ],
    'Date / Time:': ['Date / Time:', 'तारीख / समय:', 'तारीख / वेळ:'],
    'Date:': ['Date:', 'तारीख:', 'तारीख:'],
    'End:': ['End:', 'समाप्ति:', 'समाप्ती:'],
    'Error capturing image:': [
      'Error capturing image:',
      'छवि लेने में त्रुटि:',
      'प्रतिमा घेताना त्रुटी:',
    ],
    'Error generating PDF:': [
      'Error generating PDF:',
      'PDF बनाने में त्रुटि:',
      'PDF तयार करताना त्रुटी:',
    ],
    'Error loading cash collectors:': [
      'Error loading cash collectors:',
      'नकदी संग्रहकर्ता लोड करने में त्रुटि:',
      'रोख संकलक लोड करताना त्रुटी:',
    ],
    'Error loading profile:': [
      'Error loading profile:',
      'प्रोफ़ाइल लोड करने में त्रुटि:',
      'प्रोफाइल लोड करताना त्रुटी:',
    ],
    'Error opening WhatsApp:': [
      'Error opening WhatsApp:',
      'WhatsApp खोलने में त्रुटि:',
      'WhatsApp उघडताना त्रुटी:',
    ],
    'Failed to complete job:': [
      'Failed to complete job:',
      'काम पूरा नहीं हो सका:',
      'काम पूर्ण करता आले नाही:',
    ],
    'From:': ['From:', 'से:', 'पासून:'],
    'Linked job:': ['Linked job:', 'संबंधित काम:', 'संबंधित काम:'],
    'Paid:': ['Paid:', 'भुगतान किया:', 'भरले:'],
    'Payment Mode:': ['Payment Mode:', 'भुगतान का तरीका:', 'पेमेंट पद्धत:'],
    'Pending:': ['Pending:', 'बाकी:', 'प्रलंबित:'],
    'Selected:': ['Selected:', 'चयनित:', 'निवडले:'],
    'Start:': ['Start:', 'शुरुआत:', 'सुरुवात:'],
    'Status:': ['Status:', 'स्थिति:', 'स्थिती:'],
    'To:': ['To:', 'तक:', 'पर्यंत:'],
  };

  static String translate(BuildContext context, String text) {
    return translateForLocale(
        text, Localizations.localeOf(context).languageCode);
  }

  static String translateForLocale(String text, String languageCode) {
    final languageIndex = switch (languageCode) {
      'hi' => 1,
      'mr' => 2,
      _ => 0,
    };

    const paymentModePrefix = 'Payment Mode: ';
    if (text.startsWith(paymentModePrefix)) {
      final mode = text.substring(paymentModePrefix.length);
      final translationKey = switch (mode.toLowerCase()) {
        'cash' => 'Cash',
        'online' => 'Online',
        'account' => 'Account',
        'cheque' => 'Cheque',
        _ => mode,
      };
      final localizedMode = _translations[translationKey]?[languageIndex] ?? mode;
      return '${_translations['Payment Mode:']![languageIndex]} $localizedMode';
    }

    const statusPrefix = 'Status: ';
    if (text.startsWith(statusPrefix)) {
      final status = text.substring(statusPrefix.length);
      final localizedStatus = _translations[status]?[languageIndex] ?? status;
      return '${_translations['Status:']![languageIndex]} $localizedStatus';
    }

    if (text.endsWith(' Total Expense')) {
      final month = text.substring(0, text.length - ' Total Expense'.length);
      return '$month ${_translations['Total Expense']![languageIndex]}';
    }

    if (text.startsWith("Tomorrow's Jobs - ")) {
      return "${_translations["Tomorrow's Jobs"]![languageIndex]} - ${text.substring("Tomorrow's Jobs - ".length)}";
    }

    if (text.startsWith('Error: ')) {
      return '${_translations['Error:']![languageIndex]} ${text.substring('Error: '.length)}';
    }

    for (final prefix in [
      'Error downloading invoice:',
      'Error viewing invoice:'
    ]) {
      if (text.startsWith('$prefix ')) {
        return '${_translations[prefix]![languageIndex]} ${text.substring(prefix.length + 1)}';
      }
    }

    for (final prefix in ['Error taking photo:', 'Error uploading photos:']) {
      if (text.startsWith('$prefix ')) {
        return '${_translations[prefix]![languageIndex]} ${text.substring(prefix.length + 1)}';
      }
    }

    if (text.startsWith('Code: ')) {
      return '${_translations['Code:']![languageIndex]} ${text.substring('Code: '.length)}';
    }

    final cashResult =
        RegExp(r'^Cash submitted successfully to (.+)! Amount: ₹(.+)$')
            .firstMatch(text);
    if (cashResult != null) {
      return '${_translations['Cash submitted successfully to']![languageIndex]} ${cashResult.group(1)}! ${_translations['Amount:']![languageIndex]} ₹${cashResult.group(2)}';
    }

    if (text.startsWith('Cash will be collected by: ')) {
      return '${_translations['Cash will be collected by:']![languageIndex]} ${text.substring('Cash will be collected by: '.length)}';
    }

    final photoCount = RegExp(r'^(\d+) photos?$').firstMatch(text);
    if (photoCount != null) {
      final unit = photoCount.group(0)!.endsWith('photos') ? 'photos' : 'photo';
      return '${photoCount.group(1)} ${_translations[unit]![languageIndex]}';
    }

    if (text.startsWith('Qty: ')) {
      return '${_translations['Qty:']![languageIndex]} ${text.substring('Qty: '.length)}';
    }

    if (text.startsWith('Payment saved but failed to close job: ')) {
      return '${_translations['Payment saved but failed to close job:']![languageIndex]} ${text.substring('Payment saved but failed to close job: '.length)}';
    }

    if (text.startsWith('Amount cannot exceed pending amount (₹')) {
      return '${_translations['Amount cannot exceed pending amount']![languageIndex]} (₹${text.substring('Amount cannot exceed pending amount (₹'.length)}';
    }

    if (text.startsWith('Used: ₹')) {
      return '${_translations['Used']![languageIndex]}: ₹${text.substring('Used: ₹'.length)}';
    }

    if (text.startsWith('Admin note: ')) {
      return '${_translations['Admin note:']![languageIndex]} ${text.substring('Admin note: '.length)}';
    }

    final durationMatch = RegExp(r'^(\d+) Minutes$').firstMatch(text);
    if (durationMatch != null) {
      return '${durationMatch.group(1)} ${_translations['minutes']![languageIndex]}';
    }

    final recurringMatch = RegExp(
      r'^Recurring Job (\d+)/(\d+)( - Carry Forward Payment Active)?$',
    ).firstMatch(text);
    if (recurringMatch != null) {
      final activeMessage = recurringMatch.group(3) == null
          ? ''
          : ' - ${_translations['Carry Forward Payment Active']![languageIndex]}';
      return '${_translations['Recurring Job']![languageIndex]} ${recurringMatch.group(1)}/${recurringMatch.group(2)}$activeMessage';
    }

    if (text.startsWith('Started at ')) {
      return '${_translations['Started at']![languageIndex]} ${text.substring('Started at '.length)}';
    }

    if (text.startsWith('In: ')) {
      return '${_translations['In:']![languageIndex]} ${text.substring('In: '.length)}';
    }

    if (text.startsWith('Out: ')) {
      return '${_translations['Out:']![languageIndex]} ${text.substring('Out: '.length)}';
    }

    if (text.startsWith('Total: ') && text.endsWith(' hours')) {
      final hours = text.substring(7, text.length - 6);
      return '${_translations['Total:']![languageIndex]} $hours ${_translations['hours']![languageIndex]}';
    }

    if (text.startsWith('Value: ')) {
      final value = text.substring('Value: '.length);
      final unit = value.endsWith(' days') ? 'days' : 'day';
      final count = value.substring(0, value.length - unit.length - 1);
      return '${_translations['Value:']![languageIndex]} $count ${_translations[unit]![languageIndex]}';
    }

    if (text.endsWith(' jobs selected')) {
      final counts = text.substring(0, text.length - ' jobs selected'.length);
      return '$counts ${_translations['jobs selected']![languageIndex]}';
    }

    final serviceMatch = RegExp(r'^Service (\d+)$').firstMatch(text);
    if (serviceMatch != null) {
      return '${_translations['Service']![languageIndex]} ${serviceMatch.group(1)}';
    }

    final welcomeMatch = RegExp(r'^Welcome (.+)!$').firstMatch(text);
    if (welcomeMatch != null) {
      return '${_translations['Welcome']![languageIndex]} ${welcomeMatch.group(1)}!';
    }

    if (text.startsWith('Odometer Photo ')) {
      final suffix = text.substring('Odometer Photo '.length);
      final localizedSuffix = suffix == '(Optional)'
          ? ' (${_translations['Optional']![languageIndex]})'
          : suffix;
      return '${_translations['Odometer Photo']![languageIndex]}$localizedSuffix';
    }

    final tripsMatch = RegExp(r'^(\d+) trips$').firstMatch(text);
    if (tripsMatch != null) {
      return '${tripsMatch.group(1)} ${_translations['trips']![languageIndex]}';
    }

    if (text.startsWith('Showing ') && text.contains(' to ')) {
      final dates = text.substring('Showing '.length);
      final splitAt = dates.indexOf(' to ');
      if (splitAt >= 0) {
        return '${languageIndex == 1 ? 'दिखा रहे हैं ' : languageIndex == 2 ? 'दाखवत आहे ' : 'Showing '}${dates.substring(0, splitAt)} ${languageIndex == 1 ? 'से' : languageIndex == 2 ? 'ते' : 'to'} ${dates.substring(splitAt + ' to '.length)}';
      }
    }

    final usedRateMatch = RegExp(r'^Used \(₹(.+)\)$').firstMatch(text);
    if (usedRateMatch != null) {
      final label = languageIndex == 1
          ? 'उपयोग'
          : languageIndex == 2
              ? 'वापर'
              : 'Used';
      return '$label (₹${usedRateMatch.group(1)})';
    }

    final ageMatch = RegExp(r'^(\d+)([dhm]) ago$').firstMatch(text);
    if (ageMatch != null && languageIndex != 0) {
      final unit = switch (ageMatch.group(2)) {
        'd' => languageIndex == 1 ? 'दिन पहले' : 'दिवसांपूर्वी',
        'h' => languageIndex == 1 ? 'घंटे पहले' : 'तासांपूर्वी',
        _ => languageIndex == 1 ? 'मिनट पहले' : 'मिनिटांपूर्वी',
      };
      return '${ageMatch.group(1)} $unit';
    }

    final colonIndex = text.indexOf(':');
    if (colonIndex > 0 &&
        (colonIndex == text.length - 1 || text[colonIndex + 1] == ' ')) {
      final prefix = text.substring(0, colonIndex + 1);
      final localizedPrefix = _translations[prefix]?[languageIndex] ??
          _translations[text.substring(0, colonIndex)]?[languageIndex];
      if (localizedPrefix != null) {
        final separator = localizedPrefix.endsWith(':') ? '' : ':';
        return '$localizedPrefix$separator${text.substring(colonIndex + 1)}';
      }
    }

    return _translations[text]?[languageIndex] ?? text;
  }
}
