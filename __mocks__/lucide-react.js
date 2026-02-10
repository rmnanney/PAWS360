// Mock all lucide-react icons
const React = require('react');

const createMockIcon = (name) => {
  const MockIcon = (props) => {
    return React.createElement('svg', {
      'data-testid': `${name}-icon`,
      className: props.className,
      onClick: props.onClick,
      ...props
    });
  };
  MockIcon.displayName = name;
  return MockIcon;
};

module.exports = {
  GraduationCap: createMockIcon('GraduationCap'),
  DollarSign: createMockIcon('DollarSign'),
  User: createMockIcon('User'),
  MessageSquare: createMockIcon('MessageSquare'),
  BookOpen: createMockIcon('BookOpen'),
  Briefcase: createMockIcon('Briefcase'),
  AlertCircle: createMockIcon('AlertCircle'),
  Link: createMockIcon('Link'),
  MoreHorizontal: createMockIcon('MoreHorizontal'),
  CalendarDays: createMockIcon('CalendarDays'),
  Search: createMockIcon('Search'),
  Calendar: createMockIcon('Calendar'),
  Home: createMockIcon('Home'),
  Settings: createMockIcon('Settings'),
  Loader2: createMockIcon('Loader2'),
};