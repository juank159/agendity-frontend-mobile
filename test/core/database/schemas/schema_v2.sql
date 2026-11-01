CREATE TABLE "id_remaps" ("entity" TEXT NOT NULL, "from_id" TEXT NOT NULL, "to_id" TEXT NOT NULL, PRIMARY KEY ("entity", "from_id"));
CREATE TABLE "local_clients" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "lastname" TEXT NOT NULL DEFAULT '', "email" TEXT NULL, "phone" TEXT NOT NULL, "image" TEXT NULL, "address" TEXT NULL, "is_from_device" INTEGER NOT NULL DEFAULT 0 CHECK ("is_from_device" IN (0, 1)), "device_contact_id" TEXT NULL, "last_visit" TEXT NULL, "is_active" INTEGER NOT NULL DEFAULT 1 CHECK ("is_active" IN (0, 1)), "created_at" TEXT NULL, "updated_at" TEXT NULL, "notes" TEXT NULL, "birthday" TEXT NULL, "show_notes" INTEGER NOT NULL DEFAULT 0 CHECK ("show_notes" IN (0, 1)), PRIMARY KEY ("id"));
CREATE TABLE "local_documents" ("entity" TEXT NOT NULL, "id" TEXT NOT NULL, "data" TEXT NOT NULL, "ref1" TEXT NULL, "ref2" TEXT NULL, "at" TEXT NULL, PRIMARY KEY ("entity", "id"));
CREATE TABLE "outbox" ("seq" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "mutation_id" TEXT NOT NULL UNIQUE, "type" TEXT NOT NULL, "entity" TEXT NOT NULL, "entity_id" TEXT NULL, "payload" TEXT NOT NULL DEFAULT '{}', "client_time" TEXT NOT NULL, "status" TEXT NOT NULL DEFAULT 'pending', "code" TEXT NULL, "message" TEXT NULL, "attempts" INTEGER NOT NULL DEFAULT 0);
CREATE TABLE "sync_meta" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
CREATE INDEX idx_documents_at ON local_documents (entity, at);
CREATE INDEX idx_documents_ref1 ON local_documents (entity, ref1);
CREATE INDEX idx_documents_ref2 ON local_documents (entity, ref2);
