-- User id type (from Eternaltwin)
CREATE DOMAIN user_id AS UUID;
-- User display name type (from Eternaltwin)
CREATE DOMAIN user_display_name AS VARCHAR(64);

CREATE TABLE "user" (
    user_uuid USER_ID NOT NULL,
    user_kkid INT GENERATED ALWAYS AS IDENTITY,
    display_name USER_DISPLAY_NAME NOT NULL,
    "ts_register" TIMESTAMP NOT NULL,
	"ts_signin" TIMESTAMP NOT NULL,
    PRIMARY KEY (user_uuid)
);
