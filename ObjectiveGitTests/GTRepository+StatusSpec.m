//
//  GTRepository+StatusSpec
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 2013-08-08.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTRepositoryStatus)

describe(@"Checking status", ^{
	__block GTRepository *repository = nil;
	__block NSURL *targetFileURL = nil;
	__block NSError *err;

	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];

	beforeEach(^{
		repository = self.testAppFixtureRepository;
		targetFileURL = [repository.fileURL URLByAppendingPathComponent:@"main.m"];
		expect(repository).notTo(beNil());
	});

	void (^updateIndexForSubpathAndExpectStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus expectedIndexStatus) {
		__block NSError *err = nil;
		GTIndex *index = [repository indexWithError:&err];
		expect(err).to(beNil());
		expect(index).notTo(beNil());
		expect(@([index updatePathspecs:NULL error:NULL passingTest:NULL])).to(beTruthy());

		NSDictionary *renamedOptions = @{ GTRepositoryStatusOptionsFlagsKey: @(GTRepositoryStatusFlagsIncludeIgnored | GTRepositoryStatusFlagsIncludeUntracked | GTRepositoryStatusFlagsRecurseUntrackedDirectories | GTRepositoryStatusFlagsRenamesHeadToIndex) };
		expect(@([repository enumerateFileStatusWithOptions:renamedOptions error:&err usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![headToIndex.newFile.path isEqualToString:subpath]) return;
			expect(@(headToIndex.status)).to(equal(@(expectedIndexStatus)));
		}])).to(beTruthy());
		expect(err).to(beNil());
	};

	void (^expectSubpathToHaveWorkDirStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus expectedWorkDirStatus) {
		__block NSError *err = nil;
		NSDictionary *renamedOptions = @{ GTRepositoryStatusOptionsFlagsKey: @(GTRepositoryStatusFlagsIncludeIgnored | GTRepositoryStatusFlagsIncludeUntracked | GTRepositoryStatusFlagsRecurseUntrackedDirectories | GTRepositoryStatusFlagsRenamesIndexToWorkingDirectory) };
		expect(@([repository enumerateFileStatusWithOptions:renamedOptions error:&err usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![indexToWorkingDirectory.newFile.path isEqualToString:subpath]) return;
			expect(@(indexToWorkingDirectory.status)).to(equal(@(expectedWorkDirStatus)));
		}])).to(beTruthy());
		expect(err).to(beNil());
	};

	void (^expectSubpathToHaveMatchingStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus status) {
		expectSubpathToHaveWorkDirStatus(subpath, status);
		updateIndexForSubpathAndExpectStatus(subpath, status);
	};

	it(@"should recognize untracked files", ^{
		expectSubpathToHaveWorkDirStatus(@"UntrackedImage.png", GTStatusDeltaStatusUntracked);
	});

	it(@"should recognize added files", ^{
		updateIndexForSubpathAndExpectStatus(@"UntrackedImage.png", GTStatusDeltaStatusAdded);
	});

	it(@"should recognize modified files", ^{
		expect(@([NSFileManager.defaultManager removeItemAtURL:targetFileURL error:&err])).to(beTruthy());
		expect(err).to(beNil());
		expect(@([testData writeToURL:targetFileURL atomically:YES])).to(beTruthy());
		expectSubpathToHaveMatchingStatus(targetFileURL.lastPathComponent, GTStatusDeltaStatusModified);
	});

	it(@"should recognize copied files", ^{
		NSURL *copyLocation = [repository.fileURL URLByAppendingPathComponent:@"main2.m"];
		expect(@([NSFileManager.defaultManager copyItemAtURL:targetFileURL toURL:copyLocation error:&err])).to(beTruthy());
		expect(err).to(beNil());
		updateIndexForSubpathAndExpectStatus(copyLocation.lastPathComponent, GTStatusDeltaStatusCopied);
	});

	it(@"should recognize deleted files", ^{
		expect(@([NSFileManager.defaultManager removeItemAtURL:targetFileURL error:&err])).to(beTruthy());
		expect(err).to(beNil());
		expectSubpathToHaveMatchingStatus(targetFileURL.lastPathComponent, GTStatusDeltaStatusDeleted);
	});

	it(@"should recognize renamed files", ^{
		NSURL *moveLocation = [repository.fileURL URLByAppendingPathComponent:@"main-moved.m"];
		expect(@([NSFileManager.defaultManager moveItemAtURL:targetFileURL toURL:moveLocation error:&err])).to(beTruthy());
		expect(err).to(beNil());
		expectSubpathToHaveWorkDirStatus(moveLocation.lastPathComponent, GTStatusDeltaStatusRenamed);
	});

	it(@"should recognise ignored files", ^{ //at least in the default options
		expectSubpathToHaveWorkDirStatus(@".DS_Store", GTStatusDeltaStatusIgnored);
	});

	it(@"should skip ignored files if asked", ^{
		__block NSError *err = nil;
		NSDictionary *options = @{ GTRepositoryStatusOptionsFlagsKey: @(0) };
		BOOL enumerationSuccessful = [repository enumerateFileStatusWithOptions:options error:&err usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			expect(@(indexToWorkingDirectory.status)).notTo(equal(@(GTStatusDeltaStatusIgnored)));
		}];
		expect(@(enumerationSuccessful)).to(beTruthy());
		expect(err).to(beNil());
	});
	
	it(@"should report file should be ignored", ^{
		__block NSError *err = nil;
		NSURL *fileURL = [repository.fileURL URLByAppendingPathComponent:@".DS_Store"];
		BOOL success = NO;
		BOOL shouldIgnore = [repository shouldFileBeIgnored:fileURL success:&success error:&err];
		expect(@(success)).to(beTrue());
		expect(@(shouldIgnore)).to(beTrue());
		expect(err).to(beNil());
	});
	
	it(@"should report file should be ignored (convenience wrapper)", ^{
		__block NSError *err = nil;
		NSURL *fileURL = [repository.fileURL URLByAppendingPathComponent:@".DS_Store"];
		GTFileIgnoreState ignore = [repository shouldIgnoreFileURL:fileURL error:&err];
		expect(@(ignore)).to(equal(@(GTFileIgnoreStateShouldIgnore)));
		expect(err).to(beNil());
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
