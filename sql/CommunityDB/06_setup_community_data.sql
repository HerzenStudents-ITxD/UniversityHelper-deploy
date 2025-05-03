USE CommunityDB;

-- Declare variables
DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @AdminCommunityId UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555555';
DECLARE @AdminNewsId UNIQUEIDENTIFIER = '77777777-7777-7777-7777-777777777777';
DECLARE @AdminNewsPhotoId UNIQUEIDENTIFIER = '88888888-8888-8888-8888-888888888888';
DECLARE @AdminAgentId UNIQUEIDENTIFIER = '99999999-9999-9999-9999-999999999999';

-- Create admin community
INSERT INTO Communities (Id, Name, Avatar, CreatedBy, CreatedAtUtc, ModifiedBy, ModifiedAtUtc)
VALUES (
    @AdminCommunityId,
    'University Administration',
    'default-avatar.png',
    @AdminUserId,
    @Now,
    @AdminUserId,
    @Now
);

-- Add admin as community agent
INSERT INTO Agents (Id, AgentId, CommunityId)
VALUES (
    NEWID(),
    @AdminAgentId,
    @AdminCommunityId
);

-- Create sample news
INSERT INTO News (
    Id,
    Date,
    Title,
    Text,
    AuthorId,
    CommunityId
)
VALUES (
    @AdminNewsId,
    @Now,
    'Welcome to University Helper',
    'Welcome to our new platform! This is the official announcement from the university administration. We are excited to introduce new features for better communication and organization.',
    @AdminUserId,
    @AdminCommunityId
);

-- Add news photo
INSERT INTO NewsPhoto (
    Id,
    Photo,
    NewsId
)
VALUES (
    @AdminNewsPhotoId,
    'welcome-photo.jpg',
    @AdminNewsId
);

-- Add admin as news participant
INSERT INTO Participating (
    Id,
    UserId,
    NewsId
)
VALUES (
    NEWID(),
    @AdminUserId,
    @AdminNewsId
);

-- Verify setup
PRINT 'Community data setup completed';
PRINT 'Checking community data:';
SELECT 
    c.Id as CommunityId,
    c.Name as CommunityName,
    c.Avatar,
    a.AgentId,
    n.Title as NewsTitle,
    n.Text as NewsContent,
    np.Photo,
    p.UserId as ParticipantId
FROM Communities c
LEFT JOIN Agents a ON c.Id = a.CommunityId
LEFT JOIN News n ON c.Id = n.CommunityId
LEFT JOIN NewsPhoto np ON n.Id = np.NewsId
LEFT JOIN Participating p ON n.Id = p.NewsId
WHERE c.Id = @AdminCommunityId; 