import '../medical_center.dart';

const hospitals = [
  // Nairobi Hospitals
  MedicalCenter(
    name: "Kenyatta National Hospital",
    phoneNumbers: ["0202726300", "0722829500"],
    location: "Nairobi",
    longitude: "36.8019",
    latitude: "-1.3009",
  ),
  MedicalCenter(
    name: "Nairobi Hospital",
    phoneNumbers: ["0202845000", "0722204114"],
    location: "Nairobi",
    longitude: "36.8044",
    latitude: "-1.2856",
  ),
  MedicalCenter(
    name: "Aga Khan University Hospital",
    phoneNumbers: ["0203662000", "0711092000"],
    location: "Nairobi",
    longitude: "36.7785",
    latitude: "-1.2612",
  ),
  MedicalCenter(
    name: "Mater Misericordiae Hospital",
    phoneNumbers: ["0719073000", "0732163000"],
    location: "Nairobi",
    longitude: "36.8142",
    latitude: "-1.2908",
  ),
  MedicalCenter(
    name: "MP Shah Hospital",
    phoneNumbers: ["0204291100", "0722204427"],
    location: "Nairobi",
    longitude: "36.8106",
    latitude: "-1.2831",
  ),
  MedicalCenter(
    name: "The Karen Hospital",
    phoneNumbers: ["0206617000", "0733123456"],
    location: "Nairobi",
    longitude: "36.7016",
    latitude: "-1.3215",
  ),
  MedicalCenter(
    name: "Nairobi Women's Hospital",
    phoneNumbers: ["0202725590", "0712345678"],
    location: "Nairobi",
    longitude: "36.8156",
    latitude: "-1.2856",
  ),
  MedicalCenter(
    name: "The Nairobi West Hospital",
    phoneNumbers: ["0204442441", "0712345678"],
    location: "Nairobi",
    longitude: "36.7950",
    latitude: "-1.2970",
  ),
  MedicalCenter(
    name: "Avenue Hospital Parklands",
    phoneNumbers: ["0203744554", "0712345678"],
    location: "Nairobi",
    longitude: "36.7919",
    latitude: "-1.2600",
  ),
  MedicalCenter(
    name: "Coptic Hospital",
    phoneNumbers: ["0202230770", "0709123456"],
    location: "Nairobi",
    longitude: "36.8172",
    latitude: "-1.2878",
  ),
  MedicalCenter(
    name: "Lancet Laboratories",
    phoneNumbers: ["0202220000", "0712345678"],
    location: "Nairobi",
    longitude: "36.8156",
    latitude: "-1.2822",
  ),
  
  // Mombasa Hospitals
  MedicalCenter(
    name: "Coast General Teaching and Referral Hospital",
    phoneNumbers: ["0412312000", "0722123456"],
    location: "Mombasa",
    longitude: "39.6611",
    latitude: "-4.0435",
  ),
  MedicalCenter(
    name: "Mombasa Hospital",
    phoneNumbers: ["0412221000", "0712345678"],
    location: "Mombasa",
    longitude: "39.6589",
    latitude: "-4.0551",
  ),
  MedicalCenter(
    name: "Aga Khan Hospital Mombasa",
    phoneNumbers: ["041312953", "0701234567"],
    location: "Mombasa",
    longitude: "39.6567",
    latitude: "-4.0553",
  ),
  MedicalCenter(
    name: "Lamu County Referral Hospital",
    phoneNumbers: ["0424632080", "0722123456"],
    location: "Lamu",
    longitude: "40.9000",
    latitude: "-2.2694",
  ),
  
  // Kisumu Hospitals
  MedicalCenter(
    name: "Jaramogi Oginga Odinga Teaching and Referral Hospital",
    phoneNumbers: ["0572020801", "0572020803"],
    location: "Kisumu",
    longitude: "34.7520",
    latitude: "-0.0917",
  ),
  MedicalCenter(
    name: "Aga Khan Hospital Kisumu",
    phoneNumbers: ["0572024000", "0733123456"],
    location: "Kisumu",
    longitude: "34.7661",
    latitude: "-0.0917",
  ),
  MedicalCenter(
    name: "Avenue Hospital Kisumu",
    phoneNumbers: ["0572025000", "0709123456"],
    location: "Kisumu",
    longitude: "34.7694",
    latitude: "-0.0942",
  ),
  
  // Nakuru Hospitals
  MedicalCenter(
    name: "Nakuru County Referral Hospital",
    phoneNumbers: ["0512215580", "0758722032"],
    location: "Nakuru",
    longitude: "36.0703",
    latitude: "-0.3031",
  ),
  MedicalCenter(
    name: "Nakuru War Memorial Hospital",
    phoneNumbers: ["0512215111", "0722123456"],
    location: "Nakuru",
    longitude: "36.0744",
    latitude: "-0.2878",
  ),
  
  // Eldoret Hospitals
  MedicalCenter(
    name: "Moi Teaching and Referral Hospital",
    phoneNumbers: ["0532033471", "0733333238"],
    location: "Eldoret",
    longitude: "35.2839",
    latitude: "0.5143",
  ),
  MedicalCenter(
    name: "Eldoret Hospital",
    phoneNumbers: ["0532067000", "0733123456"],
    location: "Eldoret",
    longitude: "35.2750",
    latitude: "0.5169",
  ),
  
  // Other Major Towns
  MedicalCenter(
    name: "Kisii Teaching and Referral Hospital",
    phoneNumbers: ["0583063000", "0722123456"],
    location: "Kisii",
    longitude: "34.7661",
    latitude: "-0.6833",
  ),
  MedicalCenter(
    name: "Nyeri County Referral Hospital",
    phoneNumbers: ["0612032000", "0712345678"],
    location: "Nyeri",
    longitude: "36.9475",
    latitude: "-0.4197",
  ),
  MedicalCenter(
    name: "Meru Teaching and Referral Hospital",
    phoneNumbers: ["0643030000", "0701234567"],
    location: "Meru",
    longitude: "37.6569",
    latitude: "0.0469",
  ),
  MedicalCenter(
    name: "Kakamega County Referral Hospital",
    phoneNumbers: ["0562030000", "0733123456"],
    location: "Kakamega",
    longitude: "34.7520",
    latitude: "0.2842",
  ),
  MedicalCenter(
    name: "Garissa County Referral Hospital",
    phoneNumbers: ["0462100000", "0712345678"],
    location: "Garissa",
    longitude: "39.6467",
    latitude: "-0.4536",
  ),
  MedicalCenter(
    name: "Thika Level 5 Hospital",
    phoneNumbers: ["0672021000", "0722123456"],
    location: "Thika",
    longitude: "37.0694",
    latitude: "-1.0332",
  ),
  MedicalCenter(
    name: "Machakos Level 5 Hospital",
    phoneNumbers: ["0442021000", "0709123456"],
    location: "Machakos",
    longitude: "37.2639",
    latitude: "-1.5169",
  ),
  MedicalCenter(
    name: "Embu County Referral Hospital",
    phoneNumbers: ["0682031000", "0712345678"],
    location: "Embu",
    longitude: "37.4536",
    latitude: "-0.5397",
  ),
];
