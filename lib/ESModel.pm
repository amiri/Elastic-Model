package ESModel;

use Moose();
use Moose::Exporter();
use Class::Load qw(is_class_loaded load_class);
use Module::Find qw(findallmod);
use Moose::Util qw(does_role);
use Carp;

use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    class_metaroles => { class => ['ESModel::Meta::Class::Model'] },
    base_class_roles => ['ESModel::Role::Model'],
    with_meta        => [
        'has_index', 'with_types', 'analyzer', 'tokenizer',
        'filter',    'char_filter'
    ],
);

#===================================
sub has_index {
#===================================
    my ( $meta, $name, $types ) = @_;
    my @indices = grep {$_} ref $name eq 'ARRAY' ? @$name : $name;
    croak "No index name passed to has_index" unless @indices;

    $types ||= with_types($meta);
    croak "No types could be found for index: " . join( ', ', @indices )
        unless %$types;

    $meta->add_index( $_, { types => $types } ) for @indices;
}

#===================================
sub with_types {
#===================================
    my $meta = shift;
    my $prefix = shift || $meta->name;

    my %types;
    my @modules = ref $prefix eq 'ARRAY' ? @$prefix : findallmod $prefix;

    for my $class (@modules) {
        load_class $class;
        next unless does_role( $class, 'ESModel::Role::Type' );
        my $name = $class->meta->type_name or next;
        if ( my $existing = $meta->get_type($name) ) {
            croak "type_name '$name' of class $class "
                . "clashes with class $existing"
                unless $existing eq $class;
        }
        else {
            $meta->add_type( $name => $class );
            $types{ $class->meta->type_name } = $class;
        }
    }
    return \%types;
}

#===================================
sub analyzer    { shift->add_analyzer( shift,    {@_} ) }
sub tokenizer   { shift->add_tokenizer( shift,   {@_} ) }
sub filter      { shift->add_filter( shift,      {@_} ) }
sub char_filter { shift->add_char_filter( shift, {@_} ) }
#==================================

1
