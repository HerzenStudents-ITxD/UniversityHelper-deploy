USE CommunityDB;

-- Declare variables
DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @AdminCommunityId UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555555';
DECLARE @AdminAvatarId UNIQUEIDENTIFIER = '66666666-6666-6666-6666-666666666666';
DECLARE @AdminPostId UNIQUEIDENTIFIER = '77777777-7777-7777-7777-777777777777';
DECLARE @AdminLocationId UNIQUEIDENTIFIER = '88888888-8888-8888-8888-888888888888';

-- Create admin community
INSERT INTO Communities (Id, Name, Description, CreatedBy, CreatedAtUtc, IsActive)
VALUES (
    @AdminCommunityId,
    'University Administration',
    'Official community of university administration',
    @AdminUserId,
    @Now,
    1
);

-- Add community avatar
INSERT INTO CommunityAvatars (Id, CommunityId, AvatarId, IsCurrentAvatar)
VALUES (
    NEWID(),
    @AdminCommunityId,
    @AdminAvatarId,
    1
);

-- Add admin as community agent
INSERT INTO CommunityAgents (Id, CommunityId, UserId, CreatedBy, CreatedAtUtc)
VALUES (
    NEWID(),
    @AdminCommunityId,
    @AdminUserId,
    @AdminUserId,
    @Now
);

-- Create sample post
INSERT INTO Posts (
    Id,
    CommunityId,
    Title,
    Content,
    CreatedBy,
    CreatedAtUtc,
    IsActive,
    HasParticipants,
    HasLocation
)
VALUES (
    @AdminPostId,
    @AdminCommunityId,
    'Welcome to University Helper',
    'Welcome to our new platform! This is the official announcement from the university administration. We are excited to introduce new features for better communication and organization.',
    @AdminUserId,
    @Now,
    1,
    1,
    1
);

-- Add post location
INSERT INTO PostLocations (
    Id,
    PostId,
    Latitude,
    Longitude,
    Address,
    CreatedBy,
    CreatedAtUtc
)
VALUES (
    @AdminLocationId,
    @AdminPostId,
    55.7558,  -- Moscow latitude
    37.6173,  -- Moscow longitude
    'Main University Building, Room 101',
    @AdminUserId,
    @Now
);

-- Add sample post participants
INSERT INTO PostParticipants (Id, PostId, UserId, CreatedBy, CreatedAtUtc)
VALUES 
    (NEWID(), @AdminPostId, @AdminUserId, @AdminUserId, @Now),
    (NEWID(), @AdminPostId, '22222222-2222-2222-2222-222222222222', @AdminUserId, @Now),
    (NEWID(), @AdminPostId, '33333333-3333-3333-3333-333333333333', @AdminUserId, @Now);

-- Add sample post attachments
INSERT INTO PostAttachments (Id, PostId, FileId, CreatedBy, CreatedAtUtc)
VALUES 
    (NEWID(), @AdminPostId, '99999999-9999-9999-9999-999999999999', @AdminUserId, @Now),
    (NEWID(), @AdminPostId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', @AdminUserId, @Now);

-- Verify setup
PRINT 'Community data setup completed';
PRINT 'Checking community data:';
SELECT 
    c.Id as CommunityId,
    c.Name as CommunityName,
    c.Description,
    c.IsActive,
    ca.AvatarId,
    p.Title as PostTitle,
    p.Content as PostContent,
    p.IsActive as PostIsActive,
    pl.Address as Location,
    COUNT(DISTINCT pp.UserId) as ParticipantCount,
    COUNT(DISTINCT pa.Id) as AttachmentCount
FROM Communities c
LEFT JOIN CommunityAvatars ca ON c.Id = ca.CommunityId
LEFT JOIN Posts p ON c.Id = p.CommunityId
LEFT JOIN PostLocations pl ON p.Id = pl.PostId
LEFT JOIN PostParticipants pp ON p.Id = pp.PostId
LEFT JOIN PostAttachments pa ON p.Id = pa.PostId
WHERE c.Id = @AdminCommunityId
GROUP BY 
    c.Id,
    c.Name,
    c.Description,
    c.IsActive,
    ca.AvatarId,
    p.Title,
    p.Content,
    p.IsActive,
    pl.Address; 