/*
 * Apache_HW Compiler
 * Converts C-like high-level code to hardware binary instructions
 * 
 * Usage: ./compiler <input.c> [-o output.bin] [-a output.asm]
 * 
 * Author: Apache_HW Team
 * Date: 2026-02-25
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#include "isa.h"

// ==========================================
// Token Types
// ==========================================
typedef enum {
    TOKEN_INVALID,
    TOKEN_EOF,
    TOKEN_IDENT,
    TOKEN_NUMBER,
    TOKEN_OPCODE,
    TOKEN_LBRACE,
    TOKEN_RBRACE,
    TOKEN_LPAREN,
    TOKEN_RPAREN,
    TOKEN_SEMICOLON,
    TOKEN_COMMA,
    TOKEN_ASSIGN
} token_type_t;

typedef struct {
    token_type_t type;
    char         lexeme[64];
    int          value;
} token_t;

typedef struct {
    const char*  source;
    int          pos;
    int          length;
    token_t      current_token;
} lexer_t;

typedef struct {
    uint32_t*    instructions;
    int           count;
    int           capacity;
} program_t;

// ==========================================
// Lexer
// ==========================================
void lexer_init(lexer_t* lexer, const char* source) {
    lexer->source = source;
    lexer->pos = 0;
    lexer->length = strlen(source);
    memset(&lexer->current_token, 0, sizeof(token_t));
}

static bool is_whitespace(char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

static bool is_alpha(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

static bool is_digit(char c) {
    return c >= '0' && c <= '9';
}

static bool is_alnum(char c) {
    return is_alpha(c) || is_digit(c);
}

void lexer_next_token(lexer_t* lexer) {
    // Skip whitespace
    while (lexer->pos < lexer->length && is_whitespace(lexer->source[lexer->pos])) {
        lexer->pos++;
    }
    
    if (lexer->pos >= lexer->length) {
        lexer->current_token.type = TOKEN_EOF;
        return;
    }
    
    char c = lexer->source[lexer->pos];
    
    // Identifiers and keywords
    if (is_alpha(c)) {
        int start = lexer->pos;
        while (lexer->pos < lexer->length && is_alnum(lexer->source[lexer->pos])) {
            lexer->pos++;
        }
        int len = lexer->pos - start;
        if (len > 63) len = 63;
        strncpy(lexer->current_token.lexeme, &lexer->source[start], len);
        lexer->current_token.lexeme[len] = '\0';
        
        // Check for keywords
        if (strcmp(lexer->current_token.lexeme, "mac") == 0) {
            lexer->current_token.type = TOKEN_OPCODE;
            lexer->current_token.value = OPCODE_MAC;
        } else if (strcmp(lexer->current_token.lexeme, "act") == 0 ||
                   strcmp(lexer->current_token.lexeme, "activation") == 0) {
            lexer->current_token.type = TOKEN_OPCODE;
            lexer->current_token.value = OPCODE_ACT;
        } else if (strcmp(lexer->current_token.lexeme, "norm") == 0 ||
                   strcmp(lexer->current_token.lexeme, "normalization") == 0) {
            lexer->current_token.type = TOKEN_OPCODE;
            lexer->current_token.value = OPCODE_NORM;
        } else if (strcmp(lexer->current_token.lexeme, "load") == 0) {
            lexer->current_token.type = TOKEN_OPCODE;
            lexer->current_token.value = OPCODE_LOAD;
        } else if (strcmp(lexer->current_token.lexeme, "store") == 0) {
            lexer->current_token.type = TOKEN_OPCODE;
            lexer->current_token.value = OPCODE_STORE;
        } else if (strcmp(lexer->current_token.lexeme, "nop") == 0) {
            lexer->current_token.type = TOKEN_OPCODE;
            lexer->current_token.value = OPCODE_NOP;
        } else {
            lexer->current_token.type = TOKEN_IDENT;
        }
        return;
    }
    
    // Numbers (hex or decimal)
    if (is_digit(c) || (c == '0' && lexer->pos + 1 < lexer->length && 
        (lexer->source[lexer->pos + 1] == 'x' || lexer->source[lexer->pos + 1] == 'X'))) {
        int start = lexer->pos;
        if (c == '0' && lexer->pos + 1 < lexer->length && 
            (lexer->source[lexer->pos + 1] == 'x' || lexer->source[lexer->pos + 1] == 'X')) {
            lexer->pos += 2;
            while (lexer->pos < lexer->length && 
                  ((lexer->source[lexer->pos] >= '0' && lexer->source[lexer->pos] <= '9') ||
                   (lexer->source[lexer->pos] >= 'a' && lexer->source[lexer->pos] <= 'f') ||
                   (lexer->source[lexer->pos] >= 'A' && lexer->source[lexer->pos] <= 'F'))) {
                lexer->pos++;
            }
        } else {
            while (lexer->pos < lexer->length && is_digit(lexer->source[lexer->pos])) {
                lexer->pos++;
            }
        }
        int len = lexer->pos - start;
        if (len > 63) len = 63;
        strncpy(lexer->current_token.lexeme, &lexer->source[start], len);
        lexer->current_token.lexeme[len] = '\0';
        
        // Parse value
        if (lexer->current_token.lexeme[0] == '0' && 
            (lexer->current_token.lexeme[1] == 'x' || lexer->current_token.lexeme[1] == 'X')) {
            lexer->current_token.value = strtol(lexer->current_token.lexeme, NULL, 16);
        } else {
            lexer->current_token.value = atoi(lexer->current_token.lexeme);
        }
        lexer->current_token.type = TOKEN_NUMBER;
        return;
    }
    
    // Single character tokens
    lexer->pos++;
    switch (c) {
        case '{': lexer->current_token.type = TOKEN_LBRACE; break;
        case '}': lexer->current_token.type = TOKEN_RBRACE; break;
        case '(': lexer->current_token.type = TOKEN_LPAREN; break;
        case ')': lexer->current_token.type = TOKEN_RPAREN; break;
        case ';': lexer->current_token.type = TOKEN_SEMICOLON; break;
        case ',': lexer->current_token.type = TOKEN_COMMA; break;
        case '=': lexer->current_token.type = TOKEN_ASSIGN; break;
        default:  lexer->current_token.type = TOKEN_INVALID; break;
    }
    lexer->current_token.lexeme[0] = c;
    lexer->current_token.lexeme[1] = '\0';
}

static bool check_token(lexer_t* lexer, token_type_t type) {
    return lexer->current_token.type == type;
}

static bool match_token(lexer_t* lexer, token_type_t type) {
    if (check_token(lexer, type)) {
        lexer_next_token(lexer);
        return true;
    }
    return false;
}

// ==========================================
// Parser / Compiler
// ==========================================
void program_init(program_t* prog) {
    prog->capacity = 256;
    prog->count = 0;
    prog->instructions = (uint32_t*)malloc(sizeof(uint32_t) * prog->capacity);
}

void program_add(program_t* prog, uint32_t inst) {
    if (prog->count >= prog->capacity) {
        prog->capacity *= 2;
        prog->instructions = (uint32_t*)realloc(prog->instructions, 
                                                sizeof(uint32_t) * prog->capacity);
    }
    prog->instructions[prog->count++] = inst;
}

void program_free(program_t* prog) {
    free(prog->instructions);
    prog->instructions = NULL;
    prog->count = 0;
    prog->capacity = 0;
}

// Parse a single statement
void parse_statement(lexer_t* lexer, program_t* prog) {
    // Check for end
    if (lexer->current_token.type == TOKEN_EOF) {
        return;
    }
    
    // Skip unknown/invalid tokens
    if (lexer->current_token.type == TOKEN_INVALID) {
        lexer_next_token(lexer);
        parse_statement(lexer, prog);
        return;
    }
    
    // Skip identifiers (variable names, etc)
    if (lexer->current_token.type == TOKEN_IDENT) {
        lexer_next_token(lexer);
        parse_statement(lexer, prog);
        return;
    }
    
    // Skip braces
    if (lexer->current_token.type == TOKEN_LBRACE || 
        lexer->current_token.type == TOKEN_RBRACE) {
        lexer_next_token(lexer);
        parse_statement(lexer, prog);
        return;
    }
    
    // Process opcode
    if (lexer->current_token.type == TOKEN_OPCODE) {
        int opcode = lexer->current_token.value;
        int type = 0;
        
        lexer_next_token(lexer);  // consume opcode
        
        // Parse parameters
        if (match_token(lexer, TOKEN_LPAREN)) {
            
            if (lexer->current_token.type == TOKEN_NUMBER) {
                type = lexer->current_token.value;
                lexer_next_token(lexer);
            } else if (strcmp(lexer->current_token.lexeme, "relu") == 0) {
                type = ACT_RELU;
                lexer_next_token(lexer);
            } else if (strcmp(lexer->current_token.lexeme, "gelu") == 0) {
                type = ACT_GELU;
                lexer_next_token(lexer);
            } else if (strcmp(lexer->current_token.lexeme, "sigmoid") == 0) {
                type = ACT_SIGMOID;
                lexer_next_token(lexer);
            } else if (strcmp(lexer->current_token.lexeme, "layernorm") == 0) {
                type = NORM_LAYER;
                lexer_next_token(lexer);
            } else if (strcmp(lexer->current_token.lexeme, "rmsnorm") == 0) {
                type = NORM_RMS;
                lexer_next_token(lexer);
            }
            
            // Try to consume closing paren if present
            if (lexer->current_token.type == TOKEN_RPAREN) {
                lexer_next_token(lexer);
            }
        }
        
        // Try to consume semicolon
        if (lexer->current_token.type == TOKEN_SEMICOLON) {
            lexer_next_token(lexer);
        }
        
        // Generate instruction
        uint32_t inst = ENCODE(opcode, type);
        program_add(prog, inst);
        
        printf("  [0x%02X] OPCODE=0x%X TYPE=0x%02X -> 0x%08X\n", 
               prog->count-1, opcode, type, inst);
    }
    
    // Continue parsing
    parse_statement(lexer, prog);
}

// ==========================================
// Output Functions
// ==========================================
void output_binary(program_t* prog, const char* filename) {
    FILE* f = fopen(filename, "wb");
    if (!f) {
        printf("Error: Cannot open output file %s\n", filename);
        return;
    }
    
    fwrite(prog->instructions, sizeof(uint32_t), prog->count, f);
    fclose(f);
    
    printf("\nBinary output: %s (%d instructions, %d bytes)\n", 
           filename, prog->count, prog->count * 4);
}

void output_asm(program_t* prog, const char* filename) {
    FILE* f = fopen(filename, "w");
    if (!f) {
        printf("Error: Cannot open ASM file %s\n", filename);
        return;
    }
    
    fprintf(f, "; Apache_HW Assembly Output\n");
    fprintf(f, "; Total Instructions: %d\n\n", prog->count);
    
    for (int i = 0; i < prog->count; i++) {
        uint32_t inst = prog->instructions[i];
        uint8_t opcode = (inst >> 28) & 0xF;
        uint8_t type = inst & 0xFF;
        
        fprintf(f, "%04X: %08X  // %s", i, inst, opcode_to_str(opcode));
        
        if (opcode == OPCODE_ACT) {
            fprintf(f, " %s", act_type_to_str(type));
        } else if (opcode == OPCODE_NORM) {
            fprintf(f, " %s", norm_type_to_str(type));
        } else if (opcode == OPCODE_LOAD || opcode == OPCODE_STORE) {
            fprintf(f, " [0x%02X]", type);
        }
        
        fprintf(f, "\n");
    }
    
    fclose(f);
    printf("Assembly output: %s\n", filename);
}

void output_hex(program_t* prog, const char* filename) {
    FILE* f = fopen(filename, "w");
    if (!f) {
        printf("Error: Cannot open HEX file %s\n", filename);
        return;
    }
    
    for (int i = 0; i < prog->count; i++) {
        fprintf(f, "%08X\n", prog->instructions[i]);
    }
    
    fclose(f);
    printf("HEX output: %s\n", filename);
}

// ==========================================
// Main
// ==========================================
void print_usage(const char* prog) {
    printf("Apache_HW Compiler v1.0\n");
    printf("Usage: %s <input.c> [-o output.bin] [-a output.asm] [-h output.hex]\n", prog);
    printf("\nOptions:\n");
    printf("  -o    Output binary file\n");
    printf("  -a    Output assembly file\n");
    printf("  -h    Output HEX file\n");
    printf("\nExample:\n");
    printf("  %s test.c -o test.bin -a test.asm\n", prog);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    const char* input_file = argv[1];
    const char* out_bin = NULL;
    const char* out_asm = NULL;
    const char* out_hex = NULL;
    
    // Parse arguments
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            out_bin = argv[++i];
        } else if (strcmp(argv[i], "-a") == 0 && i + 1 < argc) {
            out_asm = argv[++i];
        } else if (strcmp(argv[i], "-h") == 0 && i + 1 < argc) {
            out_hex = argv[++i];
        }
    }
    
    // Read input file
    FILE* f = fopen(input_file, "r");
    if (!f) {
        printf("Error: Cannot open input file %s\n", input_file);
        return 1;
    }
    
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    char* source = (char*)malloc(size + 1);
    fread(source, 1, size, f);
    source[size] = '\0';
    fclose(f);
    
    printf("========================================\n");
    printf("Apache_HW Compiler v1.0\n");
    printf("========================================\n");
    printf("Input: %s (%ld bytes)\n\n", input_file, size);
    
    // Compile
    lexer_t lexer;
    program_t prog;
    
    lexer_init(&lexer, source);
    program_init(&prog);
    
    printf("Starting lexer...\n");
    lexer_next_token(&lexer);
    printf("First token: type=%d lexeme='%s'\n", lexer.current_token.type, lexer.current_token.lexeme);
    
    printf("Compiling...\n");
    int parse_count = 0;
    while (lexer.current_token.type != TOKEN_EOF && parse_count < 100) {
        parse_statement(&lexer, &prog);
        parse_count++;
    }
    printf("Parsed %d statements\n", parse_count);
    
    // Output
    if (out_bin) {
        output_binary(&prog, out_bin);
    }
    
    if (out_asm) {
        output_asm(&prog, out_asm);
    }
    
    if (out_hex) {
        output_hex(&prog, out_hex);
    }
    
    // Default output if none specified
    if (!out_bin && !out_asm && !out_hex) {
        output_hex(&prog, "a.hex");
    }
    
    printf("\n========================================\n");
    printf("Compilation Successful!\n");
    printf("========================================\n");
    
    // Cleanup
    free(source);
    program_free(&prog);
    
    return 0;
}
