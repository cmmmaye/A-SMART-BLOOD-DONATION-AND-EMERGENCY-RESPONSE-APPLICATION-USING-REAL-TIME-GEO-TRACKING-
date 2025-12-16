import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('blood_donation.db');
    // Ensure default admin exists (in case database was created before admin creation was added)
    await _ensureDefaultAdminExists();
    return _database!;
  }

  Future<void> _ensureDefaultAdminExists() async {
    if (_database == null) return;
    await _createDefaultAdmin(_database!);
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT UNIQUE,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT,
        name TEXT NOT NULL,
        phone_number TEXT,
        blood_type TEXT NOT NULL DEFAULT 'A+',
        user_role TEXT NOT NULL DEFAULT 'donor',
        is_admin INTEGER NOT NULL DEFAULT 0,
        profile_image_url TEXT,
        organization_type TEXT,
        location TEXT,
        is_approved INTEGER NOT NULL DEFAULT 1,
        is_blocked INTEGER NOT NULL DEFAULT 0,
        is_verified INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Blood requests table
    await db.execute('''
      CREATE TABLE blood_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        patient_name TEXT NOT NULL,
        blood_type TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        medical_center TEXT NOT NULL,
        request_date TEXT NOT NULL,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        organization_id INTEGER,
        organization_response TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (organization_id) REFERENCES users (id)
      )
    ''');

    // News table
    await db.execute('''
      CREATE TABLE news (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        image_url TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Donation offers table
    await db.execute('''
      CREATE TABLE donation_offers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        donor_name TEXT NOT NULL,
        blood_type TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        destination_type TEXT NOT NULL,
        destination_center TEXT,
        recipient_user_id INTEGER,
        organization_id INTEGER,
        donation_date TEXT NOT NULL,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        organization_response TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (recipient_user_id) REFERENCES users (id),
        FOREIGN KEY (organization_id) REFERENCES users (id)
      )
    ''');

    // Messages table for chat
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        is_announcement INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sender_id) REFERENCES users (id),
        FOREIGN KEY (receiver_id) REFERENCES users (id)
      )
    ''');
    
    // Announcements table for admin broadcasts
    await db.execute('''
      CREATE TABLE announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        target_audience TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (admin_id) REFERENCES users (id)
      )
    ''');

    // (Push device tokens table removed after undo)

    // Create indexes
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_blood_requests_user_id ON blood_requests(user_id)');
    await db.execute('CREATE INDEX idx_news_user_id ON news(user_id)');
    await db.execute('CREATE INDEX idx_donation_offers_user_id ON donation_offers(user_id)');
    await db.execute('CREATE INDEX idx_donation_offers_status ON donation_offers(status)');
    await db.execute('CREATE INDEX idx_messages_sender_id ON messages(sender_id)');
    await db.execute('CREATE INDEX idx_messages_receiver_id ON messages(receiver_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON messages(created_at)');
    await db.execute('CREATE INDEX idx_messages_is_announcement ON messages(is_announcement)');
    await db.execute('CREATE INDEX idx_announcements_created_at ON announcements(created_at)');

    // Insert initial news/tips
    await _insertInitialNews(db);
    
    // Create default admin account
    await _createDefaultAdmin(db);
  }

  Future<void> _createDefaultAdmin(Database db) async {
    try {
      // Check if any admin already exists
      final existingAdmins = await db.query(
        'users',
        where: 'is_admin = ?',
        whereArgs: [1],
        limit: 1,
      );
      
      debugPrint('Checking for existing admins: Found ${existingAdmins.length}');
      
      // Only create default admin if no admin exists
      if (existingAdmins.isEmpty) {
        // Hash default password: "admin123"
        final password = 'admin123';
        final bytes = utf8.encode(password);
        final hash = sha256.convert(bytes);
        final passwordHash = hash.toString();
        
        final adminId = await db.insert(
          'users',
          {
            'email': 'admin@blooddonation.com',
            'password_hash': passwordHash,
            'name': 'System Administrator',
            'phone_number': null,
            'blood_type': 'A+',
            'user_role': 'admin', // Admin is a separate role, not donor/recipient
            'is_admin': 1,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        
        debugPrint('✅ Default admin account created successfully!');
        debugPrint('   Email: admin@blooddonation.com');
        debugPrint('   Password: admin123');
        debugPrint('   Admin ID: $adminId');
      } else {
        debugPrint('Admin already exists, skipping default admin creation');
      }
    } catch (e) {
      debugPrint('Error creating default admin: $e');
    }
  }

  Future<void> _insertInitialNews(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Insert default admin user ID for system news (will be 1 for first user)
    final adminUserId = 1;
    
    final initialNews = [
      {
        'user_id': adminUserId,
        'title': 'Why Donate Blood?',
        'content': 'Blood donation saves lives! A single donation can help up to three people in need. Regular blood donors are the lifeline of our healthcare system, providing the critical resource needed for surgeries, trauma care, and treating chronic illnesses.',
        'created_at': now,
      },
      {
        'user_id': adminUserId,
        'title': 'Who Can Donate Blood?',
        'content': 'To donate blood, you must be at least 18 years old, weigh at least 50kg, and be in generally good health. You should have eaten something in the last 4 hours and be well-hydrated. Some health conditions and medications may make you ineligible.',
        'created_at': now,
      },
      {
        'user_id': adminUserId,
        'title': 'Blood Donation Process',
        'content': 'The donation process is simple and takes about 10-15 minutes. After completing a health questionnaire, a small blood sample is taken, then the actual donation takes place using sterile, single-use needles. Afterward, you\'ll get refreshments and rest for a few minutes.',
        'created_at': now,
      },
      {
        'user_id': adminUserId,
        'title': 'How Often Can You Donate?',
        'content': 'Blood can be donated every 56 days (approximately 8 weeks) for whole blood donations. Platelet donations can be done more frequently. Your body replenishes the donated blood within a few days, but the wait time helps ensure your health and the quality of the donated blood.',
        'created_at': now,
      },
      {
        'user_id': adminUserId,
        'title': 'Universal Blood Type',
        'content': 'Type O negative blood is known as the universal donor type because it can be given to patients of any blood type. This makes O negative donors especially valuable in emergency situations when there\'s no time to determine a patient\'s blood type.',
        'created_at': now,
      },
    ];

    for (final news in initialNews) {
      await db.insert('news', news);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add user_role column for existing databases
      await db.execute('ALTER TABLE users ADD COLUMN user_role TEXT');
      await db.execute("UPDATE users SET user_role = 'donor' WHERE user_role IS NULL");
    }
    if (oldVersion < 3) {
      // Add phone_number column for existing databases
      await db.execute('ALTER TABLE users ADD COLUMN phone_number TEXT');
    }
    if (oldVersion < 4) {
      // Add initial news items for existing databases
      await _insertInitialNews(db);
    }
    if (oldVersion < 5) {
      // Add donation offers table for existing databases
      await db.execute('''
        CREATE TABLE donation_offers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          donor_name TEXT NOT NULL,
          blood_type TEXT NOT NULL,
          contact_number TEXT NOT NULL,
          destination_type TEXT NOT NULL,
          destination_center TEXT,
          recipient_user_id INTEGER,
          donation_date TEXT NOT NULL,
          note TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (recipient_user_id) REFERENCES users (id)
        )
      ''');
      await db.execute('CREATE INDEX idx_donation_offers_user_id ON donation_offers(user_id)');
      await db.execute('CREATE INDEX idx_donation_offers_status ON donation_offers(status)');
    }
    if (oldVersion < 6) {
      // Add messages table for existing databases
      await db.execute('''
        CREATE TABLE messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sender_id INTEGER NOT NULL,
          receiver_id INTEGER NOT NULL,
          message TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (sender_id) REFERENCES users (id),
          FOREIGN KEY (receiver_id) REFERENCES users (id)
        )
      ''');
      await db.execute('CREATE INDEX idx_messages_sender_id ON messages(sender_id)');
      await db.execute('CREATE INDEX idx_messages_receiver_id ON messages(receiver_id)');
      await db.execute('CREATE INDEX idx_messages_created_at ON messages(created_at)');
    }
    if (oldVersion < 7) {
      // Add organization support
      await db.execute('ALTER TABLE users ADD COLUMN organization_type TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN location TEXT');
      // Note: blood_type already exists in the original schema, so we don't add it here
      await db.execute('ALTER TABLE blood_requests ADD COLUMN organization_id INTEGER');
      await db.execute('ALTER TABLE blood_requests ADD COLUMN organization_response TEXT');
      await db.execute('ALTER TABLE donation_offers ADD COLUMN organization_id INTEGER');
      await db.execute('ALTER TABLE donation_offers ADD COLUMN organization_response TEXT');
      await db.execute('CREATE INDEX idx_blood_requests_organization_id ON blood_requests(organization_id)');
      await db.execute('CREATE INDEX idx_donation_offers_organization_id ON donation_offers(organization_id)');
      
      // Create default admin if none exists (for existing databases)
      await _createDefaultAdmin(db);
    }
    if (oldVersion < 8) {
      // Add user status management fields
      await db.execute('ALTER TABLE users ADD COLUMN is_approved INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE users ADD COLUMN is_blocked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN is_verified INTEGER DEFAULT 0');
      // Set all existing users as approved
      await db.execute('UPDATE users SET is_approved = 1 WHERE is_approved IS NULL');
      await db.execute('UPDATE users SET is_blocked = 0 WHERE is_blocked IS NULL');
      await db.execute('UPDATE users SET is_verified = 0 WHERE is_verified IS NULL');
      // Fix admin user_role: ensure all admins have user_role = 'admin'
      await db.execute("UPDATE users SET user_role = 'admin' WHERE is_admin = 1 AND user_role != 'admin'");
    }
    if (oldVersion < 9) {
      // Add announcements support
      await db.execute('ALTER TABLE messages ADD COLUMN is_announcement INTEGER DEFAULT 0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS announcements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          admin_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          target_audience TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (admin_id) REFERENCES users (id)
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_is_announcement ON messages(is_announcement)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at)');
    }
    if (oldVersion < 10) {
      // Add firebase_uid column (kept for backward compatibility, not used)
      await db.execute('ALTER TABLE users ADD COLUMN firebase_uid TEXT');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid)');
    }
    // Version 11 migration removed (undo push)
  }

  // User operations
  Future<int> createUser({
    required String email,
    String? password,
    required String name,
    required String bloodType,
    required String userRole, // 'donor', 'recipient', or 'organization'
    String? phoneNumber,
    bool isAdmin = false,
    String? organizationType, // 'hospital', 'red_cross', or 'blood_bank'
    String? location,
  }) async {
    final db = await database;
    
    final data = <String, dynamic>{
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'blood_type': bloodType,
      'user_role': userRole,
      'is_admin': isAdmin ? 1 : 0,
      'organization_type': organizationType,
      'location': location,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Add password hash if password is provided (for legacy/local accounts)
    if (password != null) {
      final bytes = utf8.encode(password);
      final hash = sha256.convert(bytes);
      data['password_hash'] = hash.toString();
    }


    return await db.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (result.isEmpty) return null;
    
    final user = result.first;
    return _mapUserFromRow(user);
  }


  Map<String, dynamic> _mapUserFromRow(Map<String, dynamic> user) {
    return {
      'id': user['id'] as int,
      'email': user['email'] as String,
      'password_hash': user['password_hash'] as String?,
      'firebase_uid': user['firebase_uid'] as String?,
      'name': user['name'] as String,
      'phone_number': user['phone_number'] as String?,
      'blood_type': user['blood_type'] as String? ?? 'A+',
      'user_role': user['user_role'] as String? ?? 'donor',
      'is_admin': (user['is_admin'] as int) == 1,
      'profile_image_url': user['profile_image_url'] as String?,
      'organization_type': user['organization_type'] as String?,
      'location': user['location'] as String?,
      'is_approved': (user['is_approved'] as int?) ?? 1,
      'is_blocked': (user['is_blocked'] as int?) ?? 0,
      'is_verified': (user['is_verified'] as int?) ?? 0,
      'created_at': user['created_at'] as String,
    };
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    
    final user = result.first;
    return _mapUserFromRow(user);
  }

  Future<bool> verifyPassword(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user == null) return false;

    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    final passwordHash = hash.toString();

    return user['password_hash'] == passwordHash;
  }

  Future<int> updateUser({
    required int id,
    String? name,
    String? email,
    String? bloodType,
    String? profileImageUrl,
    String? organizationType,
    String? location,
    bool? isApproved,
    bool? isBlocked,
    bool? isVerified,
  }) async {
    final db = await database;
    final data = <String, dynamic>{};
    
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (bloodType != null) data['blood_type'] = bloodType;
    if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;
    if (organizationType != null) data['organization_type'] = organizationType;
    if (location != null) data['location'] = location;
    if (isApproved != null) data['is_approved'] = isApproved ? 1 : 0;
    if (isBlocked != null) data['is_blocked'] = isBlocked ? 1 : 0;
    if (isVerified != null) data['is_verified'] = isVerified ? 1 : 0;

    return await db.update(
      'users',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Admin operations
  Future<List<Map<String, dynamic>>> getAllUsers({String? role}) async {
    final db = await database;
    if (role != null) {
      // When filtering by role, exclude admins (admins should only show in "All Users")
      return await db.query(
        'users',
        where: 'user_role = ? AND is_admin = 0',
        whereArgs: [role],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query(
      'users',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, int>> getSystemStats() async {
    final db = await database;
    
    final totalUsers = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final totalDonors = await db.rawQuery("SELECT COUNT(*) as count FROM users WHERE user_role = 'donor'");
    final totalRecipients = await db.rawQuery("SELECT COUNT(*) as count FROM users WHERE user_role = 'recipient'");
    final totalOrganizations = await db.rawQuery("SELECT COUNT(*) as count FROM users WHERE user_role = 'organization'");
    final totalRequests = await db.rawQuery('SELECT COUNT(*) as count FROM blood_requests');
    final pendingRequests = await db.rawQuery("SELECT COUNT(*) as count FROM blood_requests WHERE status = 'pending'");
    final totalOffers = await db.rawQuery('SELECT COUNT(*) as count FROM donation_offers');
    final pendingOffers = await db.rawQuery("SELECT COUNT(*) as count FROM donation_offers WHERE status = 'pending'");
    final totalMessages = await db.rawQuery('SELECT COUNT(*) as count FROM messages');
    final unreadMessages = await db.rawQuery("SELECT COUNT(*) as count FROM messages WHERE is_read = 0");
    
    return {
      'total_users': totalUsers.first['count'] as int,
      'total_donors': totalDonors.first['count'] as int,
      'total_recipients': totalRecipients.first['count'] as int,
      'total_organizations': totalOrganizations.first['count'] as int,
      'total_requests': totalRequests.first['count'] as int,
      'pending_requests': pendingRequests.first['count'] as int,
      'total_offers': totalOffers.first['count'] as int,
      'pending_offers': pendingOffers.first['count'] as int,
      'total_messages': totalMessages.first['count'] as int,
      'unread_messages': unreadMessages.first['count'] as int,
    };
  }

  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final db = await database;
    return await db.query(
      'messages',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateUserPassword(int id, String passwordHash) async {
    final db = await database;
    return await db.update(
      'users',
      {'password_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    // Delete related data first (cascade delete)
    await db.delete('blood_requests', where: 'user_id = ?', whereArgs: [id]);
    await db.delete('donation_offers', where: 'user_id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'sender_id = ? OR receiver_id = ?', whereArgs: [id, id]);
    // Delete the user
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateBloodRequestStatus(int id, String status, {String? organizationResponse, int? organizationId}) async {
    final db = await database;
    final data = <String, dynamic>{'status': status};
    if (organizationResponse != null) {
      data['organization_response'] = organizationResponse;
    }
    if (organizationId != null) {
      data['organization_id'] = organizationId;
    }
    return await db.update(
      'blood_requests',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Blood request operations
  Future<int> createBloodRequest({
    required int userId,
    required String patientName,
    required String bloodType,
    required String contactNumber,
    required String medicalCenter,
    required DateTime requestDate,
    String? note,
    int? organizationId,
  }) async {
    final db = await database;

    return await db.insert(
      'blood_requests',
      {
        'user_id': userId,
        'patient_name': patientName,
        'blood_type': bloodType,
        'contact_number': contactNumber,
        'medical_center': medicalCenter,
        'request_date': requestDate.toIso8601String(),
        'note': note,
        'status': 'pending',
        'organization_id': organizationId,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getBloodRequests({
    int? userId,
    bool activeOnly = false,
  }) async {
    final db = await database;
    
    if (userId != null && activeOnly) {
      // Show all requests except 'fulfilled' ones (include pending, accepted, rejected)
      return await db.query(
        'blood_requests',
        where: 'user_id = ? AND status != ?',
        whereArgs: [userId, 'fulfilled'],
        orderBy: 'created_at DESC',
      );
    } else if (userId != null) {
      return await db.query(
        'blood_requests',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: 20,
      );
    } else if (activeOnly) {
      // Show all requests except 'fulfilled' ones
      return await db.query(
        'blood_requests',
        where: 'status != ?',
        whereArgs: ['fulfilled'],
        orderBy: 'request_date ASC',
        limit: 30,
      );
    }
    
    return await db.query(
      'blood_requests',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteBloodRequest(int id) async {
    final db = await database;
    return await db.delete(
      'blood_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // News operations
  Future<int> createNews({
    required int userId,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    final db = await database;

    return await db.insert(
      'news',
      {
        'user_id': userId,
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getNews() async {
    final db = await database;
    return await db.query(
      'news',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteNews(int id) async {
    final db = await database;
    return await db.delete(
      'news',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all users by role (donors or recipients)
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final db = await database;
    return await db.query(
      'users',
      where: 'user_role = ?',
      whereArgs: [role],
      orderBy: 'created_at DESC',
    );
  }

  // Delete all users
  Future<int> deleteAllUsers() async {
    final db = await database;
    return await db.delete('users');
  }

  // Donation offer operations
  Future<int> createDonationOffer({
    required int userId,
    required String donorName,
    required String bloodType,
    required String contactNumber,
    required String destinationType,
    String? destinationCenter,
    int? recipientUserId,
    int? organizationId,
    required DateTime donationDate,
    String? note,
  }) async {
    final db = await database;

    return await db.insert(
      'donation_offers',
      {
        'user_id': userId,
        'donor_name': donorName,
        'blood_type': bloodType,
        'contact_number': contactNumber,
        'destination_type': destinationType,
        'destination_center': destinationCenter,
        'recipient_user_id': recipientUserId,
        'organization_id': organizationId,
        'donation_date': donationDate.toIso8601String(),
        'note': note,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getDonationOffers({
    int? userId,
    bool activeOnly = false,
  }) async {
    final db = await database;
    
    if (userId != null && activeOnly) {
      // Show all offers except 'fulfilled' ones (include pending, accepted, rejected)
      return await db.query(
        'donation_offers',
        where: 'user_id = ? AND status != ?',
        whereArgs: [userId, 'fulfilled'],
        orderBy: 'created_at DESC',
      );
    } else if (userId != null) {
      return await db.query(
        'donation_offers',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: 20,
      );
    } else if (activeOnly) {
      // Show all offers except 'fulfilled' ones
      return await db.query(
        'donation_offers',
        where: 'status != ?',
        whereArgs: ['fulfilled'],
        orderBy: 'donation_date ASC',
        limit: 30,
      );
    }
    
    return await db.query(
      'donation_offers',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateDonationOfferStatus(int id, String status, {String? organizationResponse, int? organizationId}) async {
    final db = await database;
    final data = <String, dynamic>{'status': status};
    if (organizationResponse != null) {
      data['organization_response'] = organizationResponse;
    }
    if (organizationId != null) {
      data['organization_id'] = organizationId;
    }
    return await db.update(
      'donation_offers',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Organization operations
  Future<List<Map<String, dynamic>>> getBloodRequestsForOrganization(int organizationId) async {
    final db = await database;
    return await db.query(
      'blood_requests',
      where: 'organization_id = ? OR (organization_id IS NULL AND status = ?)',
      whereArgs: [organizationId, 'pending'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getDonationOffersForOrganization(int organizationId) async {
    final db = await database;
    return await db.query(
      'donation_offers',
      where: 'organization_id = ? OR (organization_id IS NULL AND destination_type != ? AND status = ?)',
      whereArgs: [organizationId, 'recipient', 'pending'],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, int>> getOrganizationStats(int organizationId) async {
    final db = await database;
    
    final totalRequests = await db.rawQuery(
      'SELECT COUNT(*) as count FROM blood_requests WHERE organization_id = ?',
      [organizationId],
    );
    
    final acceptedRequests = await db.rawQuery(
      'SELECT COUNT(*) as count FROM blood_requests WHERE organization_id = ? AND status = ?',
      [organizationId, 'accepted'],
    );
    
    final pendingRequests = await db.rawQuery(
      'SELECT COUNT(*) as count FROM blood_requests WHERE organization_id = ? AND status = ?',
      [organizationId, 'pending'],
    );
    
    final totalOffers = await db.rawQuery(
      'SELECT COUNT(*) as count FROM donation_offers WHERE organization_id = ?',
      [organizationId],
    );
    
    final acceptedOffers = await db.rawQuery(
      'SELECT COUNT(*) as count FROM donation_offers WHERE organization_id = ? AND status = ?',
      [organizationId, 'accepted'],
    );
    
    return {
      'total_requests': totalRequests.first['count'] as int,
      'accepted_requests': acceptedRequests.first['count'] as int,
      'pending_requests': pendingRequests.first['count'] as int,
      'total_offers': totalOffers.first['count'] as int,
      'accepted_offers': acceptedOffers.first['count'] as int,
    };
  }

  Future<int> deleteDonationOffer(int id) async {
    final db = await database;
    return await db.delete(
      'donation_offers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Message operations
  Future<int> createMessage({
    required int senderId,
    required int receiverId,
    required String message,
    bool isAnnouncement = false,
  }) async {
    final db = await database;

    return await db.insert(
      'messages',
      {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'is_read': 0,
        'is_announcement': isAnnouncement ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }
  
  // Announcement operations
  Future<int> createAnnouncement({
    required int adminId,
    required String title,
    required String message,
    required String targetAudience, // 'all', 'donors', 'recipients', 'organizations'
  }) async {
    final db = await database;
    
    // Create announcement record
    final announcementId = await db.insert(
      'announcements',
      {
        'admin_id': adminId,
        'title': title,
        'message': message,
        'target_audience': targetAudience,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    
    // Send as messages to target users
    List<Map<String, dynamic>> targetUsers = [];
    if (targetAudience == 'all') {
      targetUsers = await db.query('users', where: 'is_admin = 0');
    } else {
      targetUsers = await db.query(
        'users',
        where: 'user_role = ? AND is_admin = 0',
        whereArgs: [targetAudience],
      );
    }
    
    // Create messages for each target user
    for (var user in targetUsers) {
      await db.insert(
        'messages',
        {
          'sender_id': adminId,
          'receiver_id': user['id'] as int,
          'message': '📢 $title\n\n$message',
          'is_read': 0,
          'is_announcement': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    }
    
    return announcementId;
  }
  
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final db = await database;
    return await db.query(
      'announcements',
      orderBy: 'created_at DESC',
    );
  }
  
  Future<List<Map<String, dynamic>>> getUsersForMessaging({String? role}) async {
    final db = await database;
    if (role != null) {
      return await db.query(
        'users',
        where: 'user_role = ? AND is_admin = 0',
        whereArgs: [role],
        orderBy: 'name ASC',
      );
    }
    return await db.query(
      'users',
      where: 'is_admin = 0',
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required int userId,
    int? otherUserId,
  }) async {
    final db = await database;
    
    if (otherUserId != null) {
      // Get messages between two users
      return await db.query(
        'messages',
        where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        whereArgs: [userId, otherUserId, otherUserId, userId],
        orderBy: 'created_at ASC',
      );
    } else {
      // Get all messages for a user (for chat list)
      return await db.query(
        'messages',
        where: 'sender_id = ? OR receiver_id = ?',
        whereArgs: [userId, userId],
        orderBy: 'created_at DESC',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    final db = await database;
    
    // Get unique conversations (last message with each user)
    final messages = await db.rawQuery('''
      SELECT m.*, 
             CASE 
               WHEN m.sender_id = ? THEN m.receiver_id 
               ELSE m.sender_id 
             END as other_user_id
      FROM messages m
      WHERE m.id IN (
        SELECT MAX(id) 
        FROM messages 
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY 
          CASE 
            WHEN sender_id = ? THEN receiver_id 
            ELSE sender_id 
          END
      )
      ORDER BY m.created_at DESC
    ''', [userId, userId, userId, userId]);
    
    return messages;
  }

  Future<int> markMessagesAsRead({
    required int userId,
    required int otherUserId,
  }) async {
    final db = await database;
    return await db.update(
      'messages',
      {'is_read': 1},
      where: 'sender_id = ? AND receiver_id = ? AND is_read = 0',
      whereArgs: [otherUserId, userId],
    );
  }

  Future<int> getUnreadMessageCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE receiver_id = ? AND is_read = 0',
      [userId],
    );
    return result.first['count'] as int;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

}
