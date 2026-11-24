abstract final class BuildIdentity {
  static const version = String.fromEnvironment(
    'ASTRO_VERSION',
    defaultValue: '1.0.0',
  );
  static const revision = String.fromEnvironment('ASTRO_SOURCE_REVISION');
  static const shortRevision = String.fromEnvironment('ASTRO_BUILD_HASH');
  static const hasRevision = revision != '' && shortRevision != '';
  static const label = hasRevision
      ? '$version build $shortRevision'
      : '$version (development)';
  static const repository = 'https://github.com/repasscloud/astro-worker';
  static const source = '$repository/tree/$revision';
}
