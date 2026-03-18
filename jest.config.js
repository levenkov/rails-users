module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/test/javascript/**/*.test.js'],
  collectCoverageFrom: ['test/javascript/**/*.js'],
  transformIgnorePatterns: [
    'node_modules/(?!(marked)/)'
  ],
};
