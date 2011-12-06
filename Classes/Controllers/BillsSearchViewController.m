//
//  BillsSearchViewController.m
//  Created by Greg Combs on 11/21/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsSearchViewController.h"
#import "SLFDataModels.h"
#import "BillSearchParameters.h"
#import "BillsViewController.h"
#import "TableSectionHeaderView.h"
#import "ActionSheetStringPicker.h"

enum SECTIONS {
    SectionSearchInfo = 1,
    kNumSections
};


@interface BillsSearchViewController()
@property (nonatomic, retain) RKTableViewModel *tableViewModel;
@property (nonatomic, copy) NSString *selectedSession;
- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex;
- (void)configureTableItems;
- (void)configureSearchInfo;
@end

@implementation BillsSearchViewController
@synthesize state = _state;
@synthesize tableViewModel = __tableViewModel;
@synthesize selectedSession = _selectedSession;

- (id)initWithState:(SLFState *)state {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.stackWidth = 400;
        self.state = state;
        if (state)
            self.selectedSession = SLFSelectedSessionForState(state);
    }
    return self;
}

- (void)dealloc {
    self.state = nil;
    self.selectedSession = nil;
    self.tableViewModel = nil;
    [super dealloc];
}

- (void)viewDidUnload {
    self.tableViewModel = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewModel = [RKTableViewModel tableViewModelForTableViewController:(UITableViewController*)self];
    __tableViewModel.delegate = self;
    __tableViewModel.variableHeightRows = YES;
    __tableViewModel.objectManager = [RKObjectManager sharedManager];
    __tableViewModel.pullToRefreshEnabled = NO;
    NSInteger sectionIndex;
    for (sectionIndex = SectionSearchInfo;sectionIndex < kNumSections; sectionIndex++) {
        [__tableViewModel addSectionWithBlock:^(RKTableViewSection *section) {
            NSString *headerTitle = [self headerForSectionIndex:sectionIndex];
            TableSectionHeaderView *headerView = [[TableSectionHeaderView alloc] initWithTitle:headerTitle width:self.tableView.width];
            section.headerTitle = headerTitle;
            section.headerHeight = TableSectionHeaderViewDefaultHeight;
            section.headerView = headerView;
            [headerView release];
        }];
    }
    [self configureTableItems];
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:self.state];
}

- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex {
    switch (sectionIndex) {
        case SectionSearchInfo:
            return NSLocalizedString(@"Settings",@"");
        default:
            return @"";
    }
}

- (void)configureTableItems {
    if (!self.state)
        return;
    self.title = [NSString stringWithFormat:NSLocalizedString(@"Search %@ Bills",@""), _state.name];
    [self configureSearchBarWithPlaceholder:NSLocalizedString(@"HB 1, Budget, etc", @"") withConfigurationBlock:^(UISearchBar *searchBar) {
        [self configureChamberScopeTitlesForSearchBar:searchBar withState:self.state];
    }];
    [self configureSearchInfo];
}

- (void)configureSearchInfo {
    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];
    [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [StaticSubtitleCellMapping cellMapping];
        tableItem.cellMapping.style = UITableViewCellStyleValue1;
        tableItem.text = NSLocalizedString(@"State", @"");
        tableItem.detailText = self.state.name;
    }]];
    [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [SubtitleCellMapping cellMapping];
        tableItem.cellMapping.style = UITableViewCellStyleValue1;
        tableItem.text = NSLocalizedString(@"Selected Session", @"");
        if (IsEmpty(self.selectedSession))
            self.selectedSession = [self.state latestSession];
        tableItem.detailText = [self.state displayNameForSession:self.selectedSession];
        tableItem.cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell *cell, id obj, NSIndexPath *indexPath) {
            NSArray *displayNames = self.state.sessionDisplayNames;
            if (IsEmpty(displayNames))
                return;
            NSString *currentDisplayName = cell.detailTextLabel.text;
            NSInteger initialSelection = [self.state sessionIndexForDisplayName:currentDisplayName];
            ActionStringDoneBlock done = ^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                self.selectedSession = [self.state.sessions objectAtIndex:selectedIndex];
                SLFSaveSelectedSessionForState(self.selectedSession, self.state);
                [self configureSearchInfo];
            };
            ActionSheetStringPicker *picker = [[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Select a Session", @"") rows:displayNames initialSelection:initialSelection doneBlock:done cancelBlock:nil origin:self.tableView];
            picker.presentFromRect = [self.tableView rectForRowAtIndexPath:indexPath];
            [picker showActionSheetPicker];
            [picker autorelease];
        };
    }]];
    [__tableViewModel loadTableItems:tableItems inSection:SectionSearchInfo];
    [tableItems release];
}

#pragma mark - Search Bar Delegate

/*
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"stuff4");
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"stuff6");
}*/
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSInteger scopeIndex = SLFSelectedScopeIndexForKey(NSStringFromClass([self class]));
    NSString *chamber = [SLFChamber chamberTypeForSearchScopeIndex:scopeIndex];;
    NSString *resourcePath = [BillSearchParameters pathForText:searchBar.text state:self.state.stateID session:self.selectedSession chamber:chamber];
    BillsViewController *vc = [[BillsViewController alloc] initWithState:self.state resourcePath:resourcePath];
    [self stackOrPushViewController:vc];
    [vc release];
    [searchBar resignFirstResponder];
}
@end
