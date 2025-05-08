const sqlite3 = require('sqlite3').verbose();

const db = new sqlite3.Database('./database.db', (err) => {
  if (err) {
    console.error('Error opening database:', err.message);
  } else {
    console.log('Connected to SQLite database.');
    // Create users table
    db.run(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    `);
    // Create profiles table
    db.run(`
      CREATE TABLE IF NOT EXISTS profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        nickname TEXT,
        age INTEGER NOT NULL,
        gender TEXT,
        bio TEXT,
        region TEXT NOT NULL,
        city TEXT NOT NULL,
        pfp_path TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    `);
    // Create swipes table
    db.run(`
      CREATE TABLE IF NOT EXISTS swipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  target_user_id INTEGER NOT NULL,
  swipe_type TEXT NOT NULL CHECK(swipe_type IN ('left', 'right')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (target_user_id) REFERENCES users(id),
  UNIQUE(user_id, target_user_id)
)
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user1_id INTEGER NOT NULL,
        user2_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user1_id) REFERENCES users(id),
        FOREIGN KEY (user2_id) REFERENCES users(id),
        UNIQUE(user1_id, user2_id),
        CHECK(user1_id < user2_id)
      )
    `);
    db.run(`
      CREATE TABLE IF NOT EXISTS chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (match_id) REFERENCES matches(id),
        FOREIGN KEY (sender_id) REFERENCES users(id)
      )
    `);
    // Add notifications_enabled column to users table
db.run(`
  ALTER TABLE users ADD COLUMN notifications_enabled INTEGER DEFAULT 1
`, (err) => {
  if (err) {
    console.error('Error adding notifications_enabled column:', err.message);
  } else {
    console.log('Added notifications_enabled column to users table');
  }
});
    // Seed users and profiles
    db.get('SELECT COUNT(*) as count FROM users', (err, row) => {
      if (err) {
        console.error('Error checking users:', err.message);
      } else if (row.count === 0) {
        const users = [
          { name: 'Abebe Kebede', email: 'abebe1@example.com', password: '$2a$10$examplehash1', gender: 'Male', first_name: 'Abebe', last_name: 'Kebede', nickname: 'Abe', age: 22, bio: 'Loves football', region: 'Addis Ababa', city: 'Addis Ababa' },
          { name: 'Marta Tesfaye', email: 'marta2@example.com', password: '$2a$10$examplehash2', gender: 'Female', first_name: 'Marta', last_name: 'Tesfaye', nickname: 'Mar', age: 19, bio: 'Coffee enthusiast', region: 'Oromia', city: 'Adama' },
          { name: 'Yonas Alem', email: 'yonas3@example.com', password: '$2a$10$examplehash3', gender: 'Male', first_name: 'Yonas', last_name: 'Alem', nickname: 'Yoni', age: 25, bio: 'Tech lover', region: 'Amhara', city: 'Bahir Dar' },
          { name: 'Selam Bekele', email: 'selam4@example.com', password: '$2a$10$examplehash4', gender: 'Female', first_name: 'Selam', last_name: 'Bekele', nickname: 'Seli', age: 27, bio: 'Nature explorer', region: 'Tigray', city: 'Mekelle' },
          { name: 'Dawit Getachew', email: 'dawit5@example.com', password: '$2a$10$examplehash5', gender: 'Male', first_name: 'Dawit', last_name: 'Getachew', nickname: 'Dave', age: 30, bio: 'Music buff', region: 'Sidama', city: 'Hawassa' },
          { name: 'Lidya Tadesse', email: 'lidya6@example.com', password: '$2a$10$examplehash6', gender: 'Female', first_name: 'Lidya', last_name: 'Tadesse', nickname: 'Lid', age: 21, bio: 'Bookworm', region: 'Dire Dawa', city: 'Dire Dawa' },
          { name: 'Tsegaye Berhanu', email: 'tsegaye7@example.com', password: '$2a$10$examplehash7', gender: 'Male', first_name: 'Tsegaye', last_name: 'Berhanu', nickname: 'Tse', age: 28, bio: 'Fitness freak', region: 'SNNPR', city: 'Arba Minch' },
          { name: 'Hana Girma', email: 'hana8@example.com', password: '$2a$10$examplehash8', gender: 'Female', first_name: 'Hana', last_name: 'Girma', nickname: 'Han', age: 24, bio: 'Art lover', region: 'Harari', city: 'Harar' },
          { name: 'Elias Negash', email: 'elias9@example.com', password: '$2a$10$examplehash9', gender: 'Male', first_name: 'Elias', last_name: 'Negash', nickname: 'Eli', age: 32, bio: 'Traveler', region: 'Afar', city: 'Semera' },
          { name: 'Betelhem Solomon', email: 'betelhem10@example.com', password: '$2a$10$examplehash10', gender: 'Female', first_name: 'Betelhem', last_name: 'Solomon', nickname: 'Beti', age: 20, bio: 'Foodie', region: 'Gambella', city: 'Gambella' },
          // Additional 20 users (10 male, 10 female, varied ages/regions)
          { name: 'Samuel Taye', email: 'samuel11@example.com', password: '$2a$10$examplehash11', gender: 'Male', first_name: 'Samuel', last_name: 'Taye', nickname: 'Sam', age: 23, bio: 'Gamer', region: 'Oromia', city: 'Jimma' },
          { name: 'Ruth Daniel', email: 'ruth12@example.com', password: '$2a$10$examplehash12', gender: 'Female', first_name: 'Ruth', last_name: 'Daniel', nickname: 'Ruti', age: 26, bio: 'Dancer', region: 'Amhara', city: 'Gondar' },
          { name: 'Mikiyas Abebe', email: 'mikiyas13@example.com', password: '$2a$10$examplehash13', gender: 'Male', first_name: 'Mikiyas', last_name: 'Abebe', nickname: 'Miki', age: 29, bio: 'Photographer', region: 'Addis Ababa', city: 'Bole' },
          { name: 'Aster Mengistu', email: 'aster14@example.com', password: '$2a$10$examplehash14', gender: 'Female', first_name: 'Aster', last_name: 'Mengistu', nickname: 'Asti', age: 22, bio: 'Singer', region: 'Tigray', city: 'Adigrat' },
          { name: 'Bereket Lemma', email: 'bereket15@example.com', password: '$2a$10$examplehash15', gender: 'Male', first_name: 'Bereket', last_name: 'Lemma', nickname: 'Bere', age: 34, bio: 'Entrepreneur', region: 'Somali', city: 'Jijiga' },
          { name: 'Tizita Yohannes', email: 'tizita16@example.com', password: '$2a$10$examplehash16', gender: 'Female', first_name: 'Tizita', last_name: 'Yohannes', nickname: 'Tizi', age: 25, bio: 'Writer', region: 'Benishangul-Gumuz', city: 'Assosa' },
          { name: 'Fikru Teshome', email: 'fikru17@example.com', password: '$2a$10$examplehash17', gender: 'Male', first_name: 'Fikru', last_name: 'Teshome', nickname: 'Fik', age: 27, bio: 'Chef', region: 'South West Ethiopia', city: 'Bonga' },
          { name: 'Sofia Hailu', email: 'sofia18@example.com', password: '$2a$10$examplehash18', gender: 'Female', first_name: 'Sofia', last_name: 'Hailu', nickname: 'Sof', age: 19, bio: 'Student', region: 'Central Ethiopia', city: 'Bishoftu' },
          { name: 'Natnael Bekele', email: 'natnael19@example.com', password: '$2a$10$examplehash19', gender: 'Male', first_name: 'Natnael', last_name: 'Bekele', nickname: 'Nati', age: 31, bio: 'Engineer', region: 'Addis Ababa', city: 'Addis Ababa' },
          { name: 'Eden Mulugeta', email: 'eden20@example.com', password: '$2a$10$examplehash20', gender: 'Female', first_name: 'Eden', last_name: 'Mulugeta', nickname: 'Ede', age: 23, bio: 'Fashion lover', region: 'Oromia', city: 'Adama' },
          { name: 'Getachew Zewdie', email: 'getachew21@example.com', password: '$2a$10$examplehash21', gender: 'Male', first_name: 'Getachew', last_name: 'Zewdie', nickname: 'Geta', age: 26, bio: 'Cyclist', region: 'Amhara', city: 'Bahir Dar' },
          { name: 'Meseret Alemu', email: 'meseret22@example.com', password: '$2a$10$examplehash22', gender: 'Female', first_name: 'Meseret', last_name: 'Alemu', nickname: 'Mese', age: 28, bio: 'Teacher', region: 'Tigray', city: 'Mekelle' },
          { name: 'Abel Sisay', email: 'abel23@example.com', password: '$2a$10$examplehash23', gender: 'Male', first_name: 'Abel', last_name: 'Sisay', nickname: 'Abi', age: 20, bio: 'Skater', region: 'Sidama', city: 'Hawassa' },
          { name: 'Rahel Tsegaye', email: 'rahel24@example.com', password: '$2a$10$examplehash24', gender: 'Female', first_name: 'Rahel', last_name: 'Tsegaye', nickname: 'Rahi', age: 24, bio: 'Blogger', region: 'Dire Dawa', city: 'Dire Dawa' },
          { name: 'Kaleb Girma', email: 'kaleb25@example.com', password: '$2a$10$examplehash25', gender: 'Male', first_name: 'Kaleb', last_name: 'Girma', nickname: 'Kal', age: 33, bio: 'Designer', region: 'SNNPR', city: 'Arba Minch' },
          { name: 'Yodit Belay', email: 'yodit26@example.com', password: '$2a$10$examplehash26', gender: 'Female', first_name: 'Yodit', last_name: 'Belay', nickname: 'Yodi', age: 21, bio: 'Poet', region: 'Harari', city: 'Harar' },
          { name: 'Tewodros Assefa', email: 'tewodros27@example.com', password: '$2a$10$examplehash27', gender: 'Male', first_name: 'Tewodros', last_name: 'Assefa', nickname: 'Tewo', age: 29, bio: 'Musician', region: 'Afar', city: 'Semera' },
          { name: 'Zewditu Kebede', email: 'zewditu28@example.com', password: '$2a$10$examplehash28', gender: 'Female', first_name: 'Zewditu', last_name: 'Kebede', nickname: 'Zewdi', age: 25, bio: 'Painter', region: 'Gambella', city: 'Gambella' },
          { name: 'Ephrem Tadesse', email: 'ephrem29@example.com', password: '$2a$10$examplehash29', gender: 'Male', first_name: 'Ephrem', last_name: 'Tadesse', nickname: 'Ephi', age: 22, bio: 'Hiker', region: 'Oromia', city: 'Jimma' },
          { name: 'Senait Lemma', email: 'senait30@example.com', password: '$2a$10$examplehash30', gender: 'Female', first_name: 'Senait', last_name: 'Lemma', nickname: 'Sena', age: 27, bio: 'Yoga lover', region: 'Amhara', city: 'Gondar' },
        ];
        users.forEach(user => {
          db.run(
            `INSERT INTO users (name, email, password) VALUES (?, ?, ?)`,
            [user.name, user.email, user.password],
            function(err) {
              if (err) {
                console.error('Error seeding user:', err.message);
                return;
              }
              const userId = this.lastID;
              db.run(
                `INSERT INTO profiles (user_id, first_name, last_name, nickname, age, gender, bio, region, city)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                  userId,
                  user.first_name,
                  user.last_name,
                  user.nickname,
                  user.age,
                  user.gender,
                  user.bio,
                  user.region,
                  user.city,
                ],
                (err) => {
                  if (err) console.error('Error seeding profile:', err.message);
                }
              );
            }
          );
        });
        console.log('Seeded users and profiles with sample data.');
      }
    });
  }
});

module.exports = db;