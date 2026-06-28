<?php

// Keep the SQLite file together with the API files.
$dbFile = __DIR__ . "/unifind.db";

try {
    $db = new PDO("sqlite:" . $dbFile);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $db->exec("PRAGMA foreign_keys = ON");

    // Create the two related tables when the database is opened for the first time.
    $db->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            phone TEXT NOT NULL,
            password TEXT NOT NULL,
            created_at DATETIME DEFAULT (datetime('now', 'localtime'))
        )
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            report_type TEXT NOT NULL CHECK(report_type IN ('Lost', 'Found')),
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            location TEXT NOT NULL,
            report_date TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Unclaimed'
                CHECK(status IN ('Unclaimed', 'Claimed')),
            image TEXT DEFAULT '',
            created_at DATETIME DEFAULT (datetime('now', 'localtime')),
            updated_at DATETIME DEFAULT (datetime('now', 'localtime')),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    ");

    // Add a small set of sample data only when the database is empty.
    $userCount = (int) $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
    if ($userCount === 0) {
        $insertUser = $db->prepare("
            INSERT INTO users (name, email, phone, password)
            VALUES (?, ?, ?, ?)
        ");
        $insertUser->execute([
            "Demo Student",
            "student@unifind.com",
            "0123456789",
            password_hash("student123", PASSWORD_DEFAULT)
        ]);
    }

    $reportCount = (int) $db->query("SELECT COUNT(*) FROM reports")->fetchColumn();
    if ($reportCount === 0) {
        $sampleUserId = (int) $db->query("SELECT id FROM users ORDER BY id LIMIT 1")->fetchColumn();
        $insertReport = $db->prepare("
            INSERT INTO reports (
                user_id, report_type, title, category, description,
                location, report_date, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $insertReport->execute([
            $sampleUserId,
            "Lost",
            "Black Student Wallet",
            "Wallet",
            "Black leather wallet containing a student card.",
            "University Library",
            date("Y-m-d", strtotime("-2 days")),
            "Unclaimed"
        ]);
        $insertReport->execute([
            $sampleUserId,
            "Found",
            "Silver Water Bottle",
            "Other",
            "A silver insulated bottle was found near the benches.",
            "Student Centre",
            date("Y-m-d", strtotime("-1 day")),
            "Unclaimed"
        ]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    die(json_encode([
        "status" => "error",
        "message" => "Database error: " . $e->getMessage()
    ]));
}
